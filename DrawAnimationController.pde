class DrawAnimationController {
  private float directLineDelay = CONNECTION_LINE_DELAY; // Delay for direct lines
  private float curvedLineDelay = CURVED_LINE_DELAY;     // Delay for curved lines

  private boolean directLineDrawn = false;
  private boolean curvedLinesDrawn = false;
  private float timer = 0;

  void reset() {
    directLineDrawn = false;
    curvedLinesDrawn = false;
    timer = 0;
  }

  void update(float deltaTime) {
    timer += deltaTime;
  }

  boolean shouldDrawDirectLine() {
    if (!directLineDrawn && timer >= directLineDelay) {
      directLineDrawn = true;
      return true;
    }
    return directLineDrawn;  // Maintain display state
  }

  boolean shouldDrawCurvedLines() {
    if (!curvedLinesDrawn && timer >= curvedLineDelay) {
      curvedLinesDrawn = true;
      return true;
    }
    return curvedLinesDrawn;  // Maintain display state
  }
}
