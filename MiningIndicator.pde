class MiningIndicator {
  private static final int COLS = 10;
  private static final float CELL_SIZE = 4;  // Size of small squares
  private static final float CELL_GAP = 2;   // Gap between squares

  private float x, y;  // Indicator position

  void setPosition(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void draw(PGraphics pg, BlockManager blockManager, int blockHeight) {
    for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
      int row = chainId / COLS;
      int col = chainId % COLS;

      float cellX = x + col * (CELL_SIZE + CELL_GAP);
      float cellY = y + row * (CELL_SIZE + CELL_GAP);

      Block block = blockManager.getBlock(chainId, blockHeight);
      drawCell(pg, cellX, cellY, block);
    }
  }

  private void drawCell(PGraphics pg, float x, float y, Block block) {
    if (block == null) return;

    color cellColor = block.getColor();
    boolean isFilled = block.state != BlockState.UNMINED;

    pg.strokeWeight(1);
    pg.stroke(cellColor);

    if (isFilled) {
      pg.fill(cellColor);
    } else {
      pg.noFill();
    }

    pg.rect(x, y, CELL_SIZE, CELL_SIZE);
  }
}
