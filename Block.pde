enum BlockState {
  UNMINED,
  MINING,
  MINED
}

class Block {
  int chainId;
  int height;
  BlockState state;
  PVector positionGrid;
  PVector positionGraph;
  float miningProgress;
  float miningDuration;

  Block(int chainId, int height) {
    this.chainId = chainId;
    this.height = height;
    this.state = BlockState.UNMINED;
    this.positionGrid = new PVector();
    this.positionGraph = new PVector();
    this.miningProgress = 0;
    updatePositionWithGrid();
    updatePositionWithGraph();
  }

  PVector getPositionGraph() {
    return this.positionGraph;
  }

  void update(float deltaTime) {
    if (state == BlockState.MINING) {
      miningProgress += deltaTime / miningDuration; // Update progress
      if (miningProgress >= 1.0) {
        state = BlockState.MINED;
        miningProgress = 1.0;
      }
    }
  }

  void updatePositionWithGrid() {
    float x = MARGIN_LEFT + LABEL_WIDTH + ((height - 1) * GRID_WIDTH) + (GRID_WIDTH / 2);
    float y = MARGIN_TOP + (chainId * ROW_HEIGHT) + (ROW_HEIGHT / 2);
    positionGrid.set(x, y);
  }

  private void updatePositionWithGraph() {
    positionGraph = calculateGraphPosition(this.chainId);
  }

  private void draw(PGraphics pg, float x, float y) {
    pg.pushMatrix();
    pg.translate(x, y);

    switch (state) {
    case UNMINED:
      drawUnMinedState(pg);
      break;
    case MINING:
      drawMiningState(pg);
      break;
    case MINED:
      drawMinedState(pg);
      break;
    }

    pg.popMatrix();
  }

  void drawGraph(PGraphics pg) {
    draw(pg, positionGraph.x, positionGraph.y);
  }

  void drawGrid(PGraphics pg) {
    draw(pg, positionGrid.x, positionGrid.y);
  }

  private void drawUnMinedState(PGraphics pg) {
    drawBlockOutBox(pg, BLOCK_SIZE, getColor());
  }

  private void drawMiningState(PGraphics pg) {
    drawDotMatrix(pg, getColor(), true, miningProgress);
  }

  private void drawMinedState(PGraphics pg) {
    drawDotMatrix(pg, getColor(), false, miningProgress);
  }

  /**
   * Get the current block color
   * Return the corresponding color based on the block state
   */
  color getColor() {
    switch (state) {
      case UNMINED:
        return UNMINED_COLOR;
      case MINING:
        return MINING_COLOR;
      case MINED:
        return MINED_COLOR;
      default:
        return color(150); // Default gray
    }
  }
}
