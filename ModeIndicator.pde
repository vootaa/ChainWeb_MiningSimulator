class ModeIndicator {
  private float x, y;
  private float width;
  private float height;
  private DisplayMode currentMode;
  private Metrics metrics;
  
  // Initialize the mode indicator with the given display mode and metrics
  ModeIndicator(DisplayMode mode, Metrics metrics) {
    this.currentMode = mode;
    this.metrics = metrics;
    this.x = MARGIN_LEFT + metrics.getInfoTextWidth() + METRICS_PADDING * 4;
    this.y = METRICS_PADDING;
    this.width = Mode_INDICATOR_WIDTH;
    this.height = metrics.getInfoTextHeight() +  METRICS_PADDING * 2;
  }
  
  void draw(PGraphics pg) {
    pg.pushStyle();
    
    this.x = MARGIN_LEFT + metrics.getInfoTextWidth() + METRICS_PADDING * 4;
    pg.fill(METRICS_BG_COLOR);
    pg.stroke(METRICS_AXIS_COLOR);
    pg.rect(x, y, width, height);
    
    pg.fill(METRICS_TEXT_COLOR);
    pg.textAlign(CENTER, CENTER);
    textFont(largeFont);
    pg.text(currentMode.name(), x + width/2, y + height/2);
    
    pg.popStyle();
  }
  
  void nextMode() {
    int nextIndex = (currentMode.ordinal() + 1) % DisplayMode.values().length;
    currentMode = DisplayMode.values()[nextIndex];
  }
  
  DisplayMode getCurrentMode() {
    return currentMode;
  }
}
