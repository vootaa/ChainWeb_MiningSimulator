class LayerManager {
  private DisplayMode currentMode = DisplayMode.WEAVE;
  private ModeIndicator modeIndicator;
  private PGraphics infoLayer;        // Information layer
  private PGraphics staticLayer;      // Background grid and labels
  private PGraphics staticBlockLayer; // Static blocks and connections (left 5 layers)
  private PGraphics dynamicBlockLayer; // Dynamic blocks and connections (right 3 layers)
  private PGraphics xchainLayer;      // XChain mode layer
  private PGraphics graph3DLayer;      // 3D graph mode layer
  private float staticBlockOffset = 0;  // Offset for static block layer
  private float dynamicBlockOffset = 0; // Offset for dynamic block layer
  private float xchainLayerOffset = 0;  // Offset for XChain mode layer
  private float GraphModeOffset = 0;    // Offset for Graph mode layer
  private boolean isShifting = false;   // Whether a shift animation is in progress
  private float shiftTimer = 0;         // Timer for shift animation
  private float shiftDuration = 0.5;    // Duration of shift animation
  private float graph3DScaleFactor = 1.0; // Scale factor for 3D graph
  private boolean showPetersenGraph = false;

  private Metrics metrics;

  private BlockManager blockManager;
  private ConnectionManager connectionManager;
  private DrawAnimationController drawAnimController;

  LayerManager(BlockManager blockManager, ConnectionManager connectionManager, DrawAnimationController drawAnimController) {
    this.blockManager = blockManager;
    this.connectionManager = connectionManager;
    this.drawAnimController = drawAnimController;
    this.metrics = new Metrics(blockManager);
    this.modeIndicator = new ModeIndicator(this.currentMode, this.metrics);
    initializeLayers();
    drawStaticLayer();
    drawStaticBlockLayer();
    drawInfoLayer();
  }

  private void initializeLayers() {
    staticLayer = createGraphics(WINDOW_WIDTH, WINDOW_HEIGHT, P2D);
    if (staticLayer == null) {
      println("Failed to create staticLayer");
      return;
    }

    staticBlockLayer = createGraphics(WINDOW_WIDTH, WINDOW_HEIGHT, P2D);
    if (staticBlockLayer == null) {
      println("Failed to create staticBlockLayer");
      return;
    }

    dynamicBlockLayer = createGraphics(WINDOW_WIDTH, WINDOW_HEIGHT, P2D);
    if (dynamicBlockLayer == null) {
      println("Failed to create dynamicBlockLayer");
      return;
    }

    infoLayer = createGraphics(WINDOW_WIDTH, WINDOW_HEIGHT, P2D);
    if (infoLayer == null) {
      println("Failed to create infoLayer");
      return;
    }

    xchainLayer = createGraphics(WINDOW_WIDTH, WINDOW_HEIGHT, P2D);
    if (xchainLayer == null) {
      println("Failed to create xchainLayer");
      return;
    }

    graph3DLayer = createGraphics(WINDOW_WIDTH, WINDOW_HEIGHT, P3D);
    if (graph3DLayer == null) {
      println("Failed to create graph3DLayer");
      return;
    }

    // Initialize each layer
    staticLayer.beginDraw();
    staticLayer.background(BG_COLOR);
    staticLayer.endDraw();

    staticBlockLayer.beginDraw();
    staticBlockLayer.background(0, 0);
    staticBlockLayer.endDraw();

    dynamicBlockLayer.beginDraw();
    dynamicBlockLayer.background(0, 0);
    dynamicBlockLayer.endDraw();

    infoLayer.beginDraw();
    infoLayer.background(0, 0);
    infoLayer.endDraw();

    xchainLayer.beginDraw();
    xchainLayer.background(0, 0);
    xchainLayer.endDraw();

    graph3DLayer.beginDraw();
    graph3DLayer.background(0, 0);
    graph3DLayer.endDraw();
  }

  private boolean checkLayers() {
    return staticLayer != null && staticBlockLayer != null && dynamicBlockLayer != null && 
           infoLayer != null && xchainLayer != null && graph3DLayer != null;
  }

  void setDisplayMode(DisplayMode mode) {
    this.currentMode = mode;

    // Clear dynamic layers when switching modes
    if (mode == DisplayMode.XCHAIN) {
      clearDynamicBlockLayers();
    } else if (mode == DisplayMode.WEAVE) {
      redrawDynamicLayer(dynamicBlockLayer);
    } 

    drawInfoLayer();
  }

  DisplayMode getCurrentMode() {
    return this.currentMode;
  }

  void taggleDisplayMode() {
    modeIndicator.nextMode();
    setDisplayMode(modeIndicator.getCurrentMode());
  }

  void taggleShowPetersenGraph() {
    this.showPetersenGraph = !this.showPetersenGraph;
  }

  private void clearDynamicBlockLayers() {
    if (dynamicBlockLayer != null) {
      dynamicBlockLayer.beginDraw();
      dynamicBlockLayer.clear();
      dynamicBlockLayer.endDraw();
    }
  }

  void draw() {
    if (!checkLayers()) return;

    image(staticLayer, 0, 0);

    if (currentMode == DisplayMode.WEAVE) {
      drawWeaveModeContent();
    } else if (currentMode == DisplayMode.XCHAIN) {
      drawXchainModeContent();
    } else if (currentMode == DisplayMode.GRAPH) {
      draw3DModeContent();
    }

    image(infoLayer, 0, 0);
  }

  private void drawWeaveModeContent() { // Draw content for weave mode
    // Draw blocks and connections
    dynamicBlockLayer.beginDraw();
    drawDynamicBlocks(dynamicBlockLayer, blockManager, connectionManager, drawAnimController);
    dynamicBlockLayer.endDraw();

    // Apply clipping and offset
    pushStyle();
    pushMatrix();

    float clipX = MARGIN_LEFT + LABEL_WIDTH + GRID_WIDTH * 0.4;
    float clipY = MARGIN_TOP;
    float clipWidth = WINDOW_WIDTH - (MARGIN_LEFT + LABEL_WIDTH + GRID_WIDTH * 0.75 + MARGIN_RIGHT);
    float clipHeight = CONTENT_HEIGHT;

    clip(clipX, clipY, clipWidth, clipHeight);
  
    image(staticBlockLayer, staticBlockOffset, 0);
    image(dynamicBlockLayer, dynamicBlockOffset, 0);

    popMatrix();
    popStyle();
    noClip();
  }

  private void drawXchainModeContent() { // Draw content for XChain mode
    xchainLayer.beginDraw();
    xchainLayer.clear();
    
    // Draw all blocks and their connections
    for (int height = 1; height <= GRID_COUNT; height++) {
      for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
        Block currentBlock = blockManager.getBlock(chainId, height);
        Block prevBlock = blockManager.getBlock(chainId, height - 1);
        if (prevBlock != null && currentBlock != null) {
          drawXChainDirectConnection(xchainLayer, prevBlock, currentBlock);
          drawDependencyPaths(xchainLayer, currentBlock);
        }
        if (currentBlock != null ) {
          currentBlock.drawGrid(xchainLayer); 
        }
      }
    }

    xchainLayer.endDraw();

    // Apply clipping and offset
    pushStyle();
    pushMatrix();

    float clipX = MARGIN_LEFT + LABEL_WIDTH + GRID_WIDTH * 0.4;
    float clipY = MARGIN_TOP;
    float clipWidth = WINDOW_WIDTH - (MARGIN_LEFT + LABEL_WIDTH + GRID_WIDTH * 0.75 + MARGIN_RIGHT);
    float clipHeight = CONTENT_HEIGHT;

    clip(clipX, clipY, clipWidth, clipHeight);
    
    image(xchainLayer, xchainLayerOffset, 0);

    popMatrix();
    popStyle();
    noClip();
  }
  
  private void draw3DModeContent() { // Draw content for 3D graph mode
    graph3DLayer.beginDraw();
    
    // Set opaque background, same as main background color, completely covering grid lines
    graph3DLayer.background(BG_COLOR);
    
    // Set lighting
    graph3DLayer.lights();
    
    // Draw 3D network structure
    drawGraph3DNetwork(graph3DLayer, blockManager);
    
    graph3DLayer.endDraw();

    // Apply clipping and offset
    pushStyle();
    pushMatrix();

    float clipX = MARGIN_LEFT + LABEL_WIDTH + 2;
    float clipY = MARGIN_TOP + 2;
    float clipWidth = WINDOW_WIDTH - (MARGIN_LEFT + LABEL_WIDTH + MARGIN_RIGHT) - 2;
    float clipHeight = CONTENT_HEIGHT - 4;

    clip(clipX, clipY, clipWidth, clipHeight);
    
    // Draw 3D graph mode layer
    image(graph3DLayer, 0, 0);

    popMatrix();
    popStyle();
    noClip();
  }

  void adjustGraph3DScale(float amount) {
    graph3DScaleFactor += amount;
    // Limit scale range to prevent excessive zooming in or out
    graph3DScaleFactor = constrain(graph3DScaleFactor, 0.5, 2.0);
  }

  private void drawGraph3DNetwork(PGraphics pg, BlockManager blockManager) {
    pg.pushStyle();
    
    // Move origin to the center height of the left side of the layer
    pg.translate(pg.width/2, pg.height/2, 0);
    
    // Set camera and lighting - place the light source in a position that better illuminates the plane
    pg.ambientLight(80, 80, 80);  // Enhance ambient light for better visibility of objects
    pg.directionalLight(180, 180, 180, 0, 0, -1);  // Main light source from the front
    pg.pointLight(120, 120, 120, 0, 0, 200);  // Point light source near the camera

    // Pull the camera back - first pull back, then rotate
    pg.translate(0, map(mouseY, 0, height, 80, -80), -200);

    // Add slight rotation for better viewing of 3D effects
    float rotationY = map(mouseX, 0, width, PI * 0.51, -PI * 0.51);
    pg.rotateY(rotationY);

    // Calculate auto-rotation angle - slow rotation based on frameCount
    float autoRotationSpeed = 0.005; // Control rotation speed, smaller values rotate slower
    float rotationX = (frameCount * autoRotationSpeed) % TWO_PI;
    pg.rotateX(rotationX);

    // Scale factor - use global variable to store scale value, controlled by mouse wheel
    pg.scale(graph3DScaleFactor);

    // Store the 3D position of each block for subsequent drawing of connection lines
    PVector[][] blockPositions = new PVector[CHAIN_COUNT][GRID_COUNT]; // [chainId][height-1][x,y,z]
    float startX = -((GRID_COUNT - 1) * GRID_WIDTH) / 2 + GraphModeOffset;

    drawCiclesPanel(pg, blockManager, startX, rotationX, rotationY, blockPositions, showPetersenGraph);

    // Draw connection lines
    pg.noFill();
    pg.strokeWeight(1);

    for (int h = 1; h < GRID_COUNT; h++) {
      for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
        Block currentBlock = blockManager.getBlock(chainId, h+1);
        Block prevBlock = blockManager.getBlock(chainId, h);
        if (currentBlock != null ) {
          pg.stroke(currentBlock.getColor(), 150);
          PVector pos1 = blockPositions[chainId][h-1]; // Previous block
          PVector pos2 = blockPositions[chainId][h];   // Current block
          if (pos1 != null && pos2 != null) {
            // Draw connection lines between adjacent blocks on the same chain
            pg.line(pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z);
          }
        }

        ArrayList<Connection> deps = connectionManager.getConnections(chainId);
        if (deps != null) {
          for (Connection conn : deps) {
            pg.stroke(conn.lineColor, 180);
            PVector pos1 = blockPositions[conn.from][h-1]; // Previous block
            PVector pos2 = blockPositions[conn.to][h];   // Current block
            if (pos1 != null && pos2 != null && prevBlock != null && prevBlock.state == BlockState.MINED && currentBlock.state != BlockState.UNMINED) {
              // Draw cross-chain dependency connection lines
              pg.line(pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z);
            }
          }
        }
      }
    }
    
    pg.popStyle();
  }

  private void drawStaticLayer() {
    staticLayer.beginDraw();
    drawGrid(staticLayer);
    drawLabels(staticLayer);
    staticLayer.endDraw();
  }

  void drawStaticBlockLayer() {
    staticBlockLayer.beginDraw();
    drawStaticBlocks(staticBlockLayer, blockManager, connectionManager);
    staticBlockLayer.endDraw();
  }

  void drawInfoLayer() {
    infoLayer.beginDraw();
    infoLayer.clear();
    metrics.draw(infoLayer);
    modeIndicator.draw(infoLayer);
    infoLayer.endDraw();
  }

  Metrics getMetrics() {
    return metrics;
  }

  void update(float deltaTime) {
    // Update shift animation
    if (isShifting) {
      shiftTimer += deltaTime;
      float progress = min(shiftTimer / shiftDuration, 1.0);
      float targetOffset = -(GRID_WIDTH - LABEL_WIDTH/2);

      staticBlockOffset = lerp(0, targetOffset, progress);
      dynamicBlockOffset = lerp(0, targetOffset, progress);
      xchainLayerOffset = lerp(0, targetOffset, progress);
      GraphModeOffset = lerp(0, targetOffset, progress);

      if (progress >= 1.0) {
        finishShift();
      }
    }
  }

  private boolean checkDynamicFirstHeightCompleted(int height) {
    for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
      Block block = blockManager.getBlock(chainId, height);
      if (block == null || block.state != BlockState.MINED) {
        return false;
      }
    }
    return true;
  }

  private void startShiftAnimation() {
    isShifting = true;
    shiftTimer = 0;
  }

  void checkAndStartShift() {
    if (!isShifting && checkDynamicFirstHeightCompleted(STATIC_BLOCK_COUNT + 1)) {
      startShiftAnimation();
    }
  }

  private void finishShift() {
    isShifting = false;
    blockManager.shiftBlocksLeft();

    staticBlockOffset = 0;
    dynamicBlockOffset = 0;
    xchainLayerOffset = 0;
    GraphModeOffset = 0;
    
    CURRENT_BLOCK_HEIGHT++;
    metrics.onShift();

    drawStaticLayer();

    if (currentMode == DisplayMode.WEAVE) {
      redrawDynamicLayer(dynamicBlockLayer);
    }

    drawAnimController.reset();
  }
}
