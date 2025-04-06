void drawGrid(PGraphics pg) {
  pg.stroke(GRID_COLOR);
  pg.strokeWeight(1);

  float startX = MARGIN_LEFT + LABEL_WIDTH;
  float startY = MARGIN_TOP;
  float gridEndX = WINDOW_WIDTH - MARGIN_RIGHT;
  float gridEndY = WINDOW_HEIGHT - MARGIN_BOTTOM;

  // Draw vertical lines
  for (int i = 0; i <= GRID_COUNT; i++) {
    float x = (i == GRID_COUNT) ? gridEndX : startX + (i * GRID_WIDTH);
    pg.line(x, startY, x, gridEndY);
  }

  // Draw horizontal lines
  for (int i = 0; i <= CHAIN_COUNT; i++) {
    float y = startY + (i * ROW_HEIGHT);
    pg.line(startX, y, gridEndX, y);
  }
}

void drawLabels(PGraphics pg) {
  // Call functions to draw height and chain labels
  drawHeightLabels(pg);
  drawChainLabels(pg);
}

void drawChainLabels(PGraphics pg) {
  pg.textFont(smallFont);
  pg.fill(BG_COLOR);
  pg.noStroke();
  pg.rect(0, 0, MARGIN_LEFT + LABEL_WIDTH - LABEL_PADDING, WINDOW_HEIGHT);

  pg.fill(LABEL_COLOR);
  pg.textAlign(RIGHT, CENTER);

  pg.text("CHAIN", MARGIN_LEFT + LABEL_WIDTH, MARGIN_TOP - LABEL_PADDING);

  for (int i = 0; i < CHAIN_COUNT; i++) {
    float y = MARGIN_TOP + (i * ROW_HEIGHT) + (ROW_HEIGHT / 2);
    pg.text("C" + i, MARGIN_LEFT + LABEL_WIDTH - LABEL_PADDING, y);
  }
}

void drawHeightLabels(PGraphics pg) {
  pg.textFont(smallFont);
  pg.fill(BG_COLOR);
  pg.noStroke();
  pg.rect(MARGIN_LEFT, 0, WINDOW_WIDTH - MARGIN_LEFT - MARGIN_RIGHT, MARGIN_TOP);

  pg.fill(LABEL_COLOR);
  pg.textAlign(CENTER, BOTTOM);

  for (int i = 0; i < GRID_COUNT; i++) {
    float x = MARGIN_LEFT + LABEL_WIDTH + (i * GRID_WIDTH) + (GRID_WIDTH / 2);
    pg.text(formatNumber(CURRENT_BLOCK_HEIGHT + i), x, MARGIN_TOP - LABEL_PADDING);
  }
}

void drawArrow(PGraphics pg, float x, float y, float angle) {
  pg.pushMatrix();
  pg.translate(x, y);
  pg.rotate(angle);
  pg.fill(ARROW_COLOR);
  pg.noStroke();
  pg.triangle(0, 0, -ARROW_SIZE, -ARROW_SIZE/2, -ARROW_SIZE, ARROW_SIZE/2);
  pg.popMatrix();
}

void drawDirectConnection(PGraphics pg, float x1, float y1, float x2, float y2) {
  float offset = BLOCK_SIZE / 2;
  float startX = x1 + offset;
  float endX = x2 - offset;

  pg.stroke(CONNECTION_LINE_COLOR);
  pg.strokeWeight(2);
  pg.line(startX, y1, endX, y2);

  float arrowX = startX + (endX - startX) * 0.9;
  float angle = atan2(y2 - y1, endX - startX);
  drawArrow(pg, arrowX, y1, angle);
}

void drawCurvedConnection(PGraphics pg, float x1, float y1, float x2, float y2, color lineColor) {
  float offset = BLOCK_SIZE / 2;
  float startX = x1 + offset;
  float endX = x2 - offset;

  // Calculate control points
  float dx = endX - startX;
  float dy = y2 - y1;
  float dist = sqrt(dx*dx + dy*dy);
  float curvature = dist * 0.2;

  float cpX1 = startX + dx * 0.25;
  float cpY1 = y1 + (dy > 0 ? -curvature : curvature);
  float cpX2 = endX - dx * 0.25;
  float cpY2 = y2 + (dy > 0 ? curvature : -curvature);

  pg.stroke(lineColor);
  pg.strokeWeight(2);
  pg.noFill();
  pg.bezier(startX, y1, cpX1, cpY1, cpX2, cpY2, endX, y2);
}

void drawStaticBlocks(PGraphics pg, BlockManager blockManager, ConnectionManager connectionManager) {
  pg.beginDraw();

  // 1. Draw static blocks (layers 1-5)
  for (int height = 1; height <= STATIC_BLOCK_COUNT; height++) {
    for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
      Block block = blockManager.getBlock(chainId, height);
      if (block != null && block.state == BlockState.MINED) {
        block.drawGrid(pg);
      }
    }
  }

  // 2. Draw connections (starting from layer 2)
  for (int height = 2; height <= STATIC_BLOCK_COUNT; height++) {
    for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
      Block currentBlock = blockManager.getBlock(chainId, height);
      Block prevBlock = blockManager.getBlock(chainId, height - 1);

      if (currentBlock != null && prevBlock != null) {
        // Draw cross-chain connections
        ArrayList<Connection> deps = connectionManager.getConnections(chainId);
        if (deps != null) {
          for (Connection conn : deps) {
            Block fromBlock = blockManager.getBlock(conn.from, height - 1);
            if (fromBlock != null) {
              drawCurvedConnection(pg,
                fromBlock.positionGrid.x, fromBlock.positionGrid.y,
                currentBlock.positionGrid.x, currentBlock.positionGrid.y,
                conn.lineColor);
            }
          }
        }
        // Draw direct connections
        drawDirectConnection(pg,
          prevBlock.positionGrid.x, prevBlock.positionGrid.y,
          currentBlock.positionGrid.x, currentBlock.positionGrid.y);
      }
    }
  }

  pg.endDraw();
}

void drawDynamicBlocks(PGraphics pg, BlockManager blockManager, ConnectionManager connectionManager, DrawAnimationController animController) {
  pg.beginDraw();

  Block miningBlock = connectionManager.getCurrentMiningBlock();
  if (miningBlock != null) {
    // Directly draw the block without delay
    miningBlock.drawGrid(pg);

    if (miningBlock.state == BlockState.MINING) {
      // Delayed drawing of direct connections
      Block prevBlock = blockManager.getBlock(miningBlock.chainId, miningBlock.height - 1);
      if (prevBlock != null && prevBlock.state == BlockState.MINED &&
        animController.shouldDrawDirectLine()) {

        drawDirectConnection(pg,
          prevBlock.positionGrid.x, prevBlock.positionGrid.y,
          miningBlock.positionGrid.x, miningBlock.positionGrid.y);
      }

      // Delayed drawing of curved connections
      if (animController.shouldDrawCurvedLines()) {
        for (Connection conn : connectionManager.getActiveConnections()) {
          Block fromBlock = blockManager.getBlock(conn.from, miningBlock.height - 1);
          if (fromBlock != null && fromBlock.state == BlockState.MINED) {
            drawCurvedConnection(pg,
              fromBlock.positionGrid.x, fromBlock.positionGrid.y,
              miningBlock.positionGrid.x, miningBlock.positionGrid.y,
              conn.lineColor);
          }
        }
      }
    }
  }

  pg.endDraw();
}

void redrawDynamicLayer(PGraphics pg) {
  pg.beginDraw();
  pg.clear();

  // Draw the last three layers of mined blocks and connections
  for (int height = STATIC_BLOCK_COUNT + 1; height <= GRID_COUNT; height++) {
    // 1. Draw connection lines (from the previous layer to the current layer)
    for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
      Block currentBlock = blockManager.getBlock(chainId, height);
      if (currentBlock != null && currentBlock.state == BlockState.MINED) {
        // Draw direct connections
        Block prevBlock = blockManager.getBlock(chainId, height - 1);
        if (prevBlock != null && prevBlock.state == BlockState.MINED) {
          drawDirectConnection(pg,
            prevBlock.positionGrid.x, prevBlock.positionGrid.y,
            currentBlock.positionGrid.x, currentBlock.positionGrid.y);
        }

        // Draw cross-chain connections
        ArrayList<Connection> deps = connectionManager.getConnections(chainId);
        if (deps != null) {
          for (Connection conn : deps) {
            Block fromBlock = blockManager.getBlock(conn.from, height - 1);
            if (fromBlock != null && fromBlock.state == BlockState.MINED) {
              drawCurvedConnection(pg,
                fromBlock.positionGrid.x, fromBlock.positionGrid.y,
                currentBlock.positionGrid.x, currentBlock.positionGrid.y,
                conn.lineColor);
            }
          }
        }
      }
    }

    // 2. Draw blocks (ensure blocks are displayed above connection lines)
    for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
      Block block = blockManager.getBlock(chainId, height);
      if (block != null && block.state == BlockState.MINED) {
        block.drawGrid(pg);
      }
    }
  }

  pg.endDraw();
}

void drawDotMatrix(PGraphics pg, color dotColor, boolean isMing, float miningProgress) {
  float size = BLOCK_SIZE;
  int dotCount = 3;  // 3x3 dot matrix
  float dotSize = size / (dotCount + 1);
  float spacing = dotSize;

  // Calculate starting position to center the dot matrix
  float startX = -size/2 + dotSize;
  float startY = -size/2 + dotSize;

  // Draw dot matrix
  for (int i = 0; i < dotCount; i++) {
    for (int j = 0; j < dotCount; j++) {
      float x = startX + j * spacing;
      float y = startY + i * spacing;

      pg.noStroke();

      if (isMing) {
        float dotProgress = (float)(i * dotCount + j) / (dotCount * dotCount);
        float currentDotSize = dotSize;
        int alpha = 255;

        if (dotProgress > miningProgress) {
          currentDotSize *= 0.5;
          alpha = 100;
        }
        pg.fill(red(dotColor), green(dotColor), blue(dotColor), alpha);
        pg.circle(x, y, currentDotSize);
      } else {
        pg.fill(dotColor);
        pg.circle(x, y, dotSize);
      }
    }
  }

  // Draw outer box
  drawBlockOutBox(pg, size, dotColor);
}

void drawBlockOutBox(PGraphics pg, float size, color dotColor) {
  pg.noFill();
  pg.stroke(dotColor);
  pg.strokeWeight(1);
  pg.rectMode(CENTER);
  pg.rect(0, 0, size, size);
}

void drawXChainDirectConnection(PGraphics pg, Block prevBlock, Block currentBlock) {
  float x1 = prevBlock.positionGrid.x;
  float y1 = prevBlock.positionGrid.y;
  float x2 = currentBlock.positionGrid.x;
  float y2 = currentBlock.positionGrid.y;

  float offset = BLOCK_SIZE / 2;
  float startX = x1 + offset;
  float endX = x2 - offset;

  // Calculate direction and length of the connection line
  float dx = endX - startX;
  float dy = y2 - y1;
  float lineLength = sqrt(dx*dx + dy*dy);

  // Draw base connection line
  pg.strokeWeight(1);
  pg.stroke(BASE_DOT_COLOR);
  pg.line(startX, y1, endX, y2);

  // Calculate the effective length of the drawable area
  float effectiveLength = lineLength - (DOT_MARGIN * 2);
  if (effectiveLength <= 0) return;

  int dotCount = floor(effectiveLength / BASE_DOT_SPACING);
  if (dotCount < 1) return;

  float actualSpacing = effectiveLength / dotCount;

  // Get base color
  color baseColor = currentBlock.getColor();

  // Calculate the position of the active point
  float activePoint = (currentBlock.state == BlockState.MINING) ?
    currentBlock.miningProgress * (dotCount + 2) : -1;

  // Draw all dots
  pg.noStroke();

  for (int i = 0; i <= dotCount; i++) {
    float t = i / float(dotCount);
    float adjustedT = map(t, 0, 1, DOT_MARGIN/lineLength, 1 - DOT_MARGIN/lineLength);

    float x = startX + dx * adjustedT;
    float y = y1 + dy * adjustedT;

    // Draw base dots first
    pg.fill(baseColor, 180);  // Base dots use semi-transparent effect
    pg.circle(x, y, BASE_DOT_SIZE);

    // Only show active dot effect in mining state
    if (currentBlock.state == BlockState.MINING &&
      i <= activePoint && i >= activePoint - 1) {
      float activeFactor = 1.0 - (activePoint - i);  // Activation factor between 0 and 1

      // Draw glow effect
      pg.fill(baseColor, 100);
      pg.circle(x, y, BASE_DOT_SIZE * (2.0 + activeFactor));

      // Draw highlight dot
      pg.fill(lerpColor(baseColor, color(255), 0.3));  // Mix some white
      pg.circle(x, y, BASE_DOT_SIZE * (1.5 + activeFactor * 0.5));
    }
  }
}

void drawXCrossConnection(PGraphics pg, CurveAnimationController curveController, Block fromBlock, Block toBlock ) {
  // 1. Calculate basic parameters
  float offset = BLOCK_SIZE / 2;
  float startX = fromBlock.positionGrid.x + offset;
  float endX = toBlock.positionGrid.x - offset;
  float y1 = fromBlock.positionGrid.y;
  float y2 = toBlock.positionGrid.y;

  // Use the controller to get the curvature factor
  float curveFactor = curveController.getCurveFactor();

  // 2. Calculate Bezier curve control points
  float dx = endX - startX;
  float dy = y2 - y1;
  float dist = sqrt(dx*dx + dy*dy);
  float curvature = dist * curveFactor;

  float cpX1 = startX + dx * curveFactor;
  float cpY1 = y1 + (dy > 0 ? -curvature : curvature);
  float cpX2 = endX - dx * curveFactor;
  float cpY2 = y2 + (dy > 0 ? curvature : -curvature);

  // 3. Draw base curve
  pg.strokeWeight(1);
  pg.stroke(BASE_DOT_COLOR);
  pg.noFill();
  pg.bezier(startX, y1, cpX1, cpY1, cpX2, cpY2, endX, y2);

  // 4. Calculate points on the curve
  int dotCount = floor(dist / BASE_DOT_SPACING);
  if (dotCount < 1) return;

  pg.noStroke();
  for (int i = 0; i <= dotCount; i++) {
    float t = i / float(dotCount);

    // Calculate the position of the point on the Bezier curve
    float x = bezierPoint(startX, cpX1, cpX2, endX, t);
    float y = bezierPoint(y1, cpY1, cpY2, y2, t);

    pg.fill(ART_DOT_COLOR);
    pg.circle(x, y, BASE_DOT_SIZE * 0.5);
  }
}

void drawDependencyPaths(PGraphics pg, Block block) {
  if (block != null && block.state == BlockState.MINING) {
    curveController.update();

    // Draw dependency paths layer by layer
    for (int layer = 0; layer < GRID_COUNT - 1; layer++) {
      ArrayList<Connection> layerPaths = dependencyTracer.getDependencyPathsForLayer(block.chainId, layer);

      for (Connection conn : layerPaths) {
        Block fromBlock = blockManager.getBlock(conn.from, block.height - 1 - layer);
        Block toBlock = blockManager.getBlock(conn.to, block.height - layer);

        if (fromBlock != null && toBlock != null) {
          drawXCrossConnection(pg, curveController, fromBlock, toBlock);
        }
      }
    }
  }
}

void drawCiclesPanel(PGraphics pg, BlockManager blockManager, float startX, float rotateX, float rotateY, PVector[][] blockPositions, boolean showPetersenGraph) {
  // Draw GRID_COUNT planes
  for (int idx = 0; idx < GRID_COUNT; idx++) {
    float x =  startX + idx * GRID_WIDTH;
    
    pg.pushMatrix();
    pg.translate(x, 0, 0); // Translate to the position of each plane
    pg.rotateY(PI/2); // Rotate 90 degrees to make the plane perpendicular to the screen
  
    drawCicles(pg, GRAPH_CIRCLE_COLOR);
    drawCircleLabel(pg, (idx % 2 ==0) ? "CHAINWEB":"KADENA", idx);

    // Draw blocks and store positions
    for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
      Block currentBlock = blockManager.getBlock(chainId, idx+1);
      if (currentBlock != null ) {
        PVector pos = currentBlock.getPositionGraph();
        float blockX = pos.x;
        float blockY = pos.y;
        float jitter = 0;
        float rotationAmount = 0;
        if (currentBlock.state == BlockState.MINING) {
          float jitterFactor = sin(frameCount * 0.1) * cos(frameCount * 0.07);
          float jitterAmplitude = BLOCK_SIZE * map(currentBlock.miningProgress, 0, 1, 0.3, 1.0);
          jitter = jitterFactor * jitterAmplitude;
        }

        // Store the 3D position of the block (considering plane rotation)
        blockPositions[chainId][idx] = new PVector(x + jitter, blockY , -blockX); // Note the negative Z-axis value due to 90-degree rotation

        pg.pushMatrix();
        if (jitter != 0) {
            pg.translate(blockX, blockY, jitter); // Translate to block position with jitter
            pg.rotateY(-PI/2 - rotateY);
            pg.rotateX(-rotateX);
            pg.translate(-blockX, -blockY, 0);     // Translate back only position coords
        }
        currentBlock.drawGraph(pg);
        pg.popMatrix();
      }
    }
    
    pg.popMatrix();
  }

  if (showPetersenGraph) {
    // Draw PetersenGraph
    float x1 = startX - 0.5 * GRID_WIDTH;
    float x2 = startX + (GRID_COUNT - 0.5) * GRID_WIDTH;
    drawPetersenGraph(pg, x1);
    drawPetersenGraph(pg, x2);
  }
}

void drawPetersenGraph(PGraphics pg, float x) {
  pg.pushMatrix();
  pg.translate(x, 0, 0); // Translate to the position of each plane
  pg.rotateY(PI/2);
  drawCicles(pg, GRAPH_Petersen_CIRCLE_COLOR);
  drawCircleLabel(pg, "Petersen Graph", -1);

  pg.stroke(GRAPH_Petersen_LINE_COLOR);
  int idx = 0;
  for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
    ArrayList<Connection> deps = connectionManager.getConnections(chainId);
    if (deps != null) {
      for (Connection conn : deps) {
        if (conn.from > conn.to) { // Since it's a bidirectional connection, only draw once, 30/60
          PVector fromPos = calculateGraphPosition(conn.from);
          PVector toPos = calculateGraphPosition(conn.to);
          pg.line(fromPos.x, fromPos.y, toPos.x, toPos.y);
        }
      }
    }

    drawChainIdLabel(pg, chainId);
  }
  pg.popMatrix();
}

// Draw ChainID labels for each block position
void drawChainIdLabel(PGraphics pg, int chainId) {
  PVector pos = calculateGraphPosition(chainId);

  pg.pushStyle();

  // Set label style
  pg.textFont(tinyFont);
  pg.fill(LABEL_COLOR);
  pg.textAlign(CENTER, CENTER);
  
  // Draw small circle
  pg.noFill();
  pg.strokeWeight(2);
  pg.ellipse(pos.x, pos.y, BLOCK_SIZE * 1.4, BLOCK_SIZE * 1.4);
  
  // Draw label text
  pg.pushMatrix();
  pg.translate(pos.x, pos.y);
  pg.rotate(getAngleByChainId(chainId) + PI/2);
  pg.text("C" + chainId, 0, 0);
  pg.popMatrix();
  
  pg.popStyle();
}

void drawCicles(PGraphics pg, color cc ) {
  // Draw concentric circles
  pg.noFill();
  pg.strokeWeight(1);
  pg.stroke(cc);

  pg.ellipse(0, 0, GRAPH_OUTER_RADIUS * 2, GRAPH_OUTER_RADIUS * 2);
  pg.ellipse(0, 0, GRAPH_MIDDLE_RADIUS * 2, GRAPH_MIDDLE_RADIUS * 2);
  pg.ellipse(0, 0, GRAPH_INNER_RADIUS * 2, GRAPH_INNER_RADIUS * 2);
}

void drawCircleLabel(PGraphics pg, String label, int idx) {
  pg.pushStyle();
  pg.fill(GRAPH_LABEL_COLOR);
  pg.textAlign(CENTER, CENTER);
  
  // Top - no rotation needed
  pg.textFont(largeFont);
  pg.text(label, 0, -GRAPH_OUTER_RADIUS - 20);

  pg.pushMatrix();
  // Bottom - rotate 180 degrees
  pg.translate(0, GRAPH_OUTER_RADIUS + 20);
  pg.rotate(PI);
  if (idx < 0) {
    pg.text(label, 0, 0);
  } else {
    pg.fill(GRAPH_HEIGHT_LABEL_COLOR);
    pg.textFont(tinyFont);
    pg.text("BLOCK HEIGHT\n" + formatNumber(CURRENT_BLOCK_HEIGHT + idx), 0, 0);
  }
  pg.popMatrix();
  
  pg.popStyle();
}