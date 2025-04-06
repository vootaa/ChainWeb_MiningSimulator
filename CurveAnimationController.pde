class CurveAnimationController {
  private float curveFactor;
  private float curveDirection;
  
  public CurveAnimationController() {
    this.curveFactor = MIN_CURVE_FACTOR;
    this.curveDirection = 1;
  }
  
  public float getCurveFactor() {
    return curveFactor;
  }
  
  public void update() {
    curveFactor += CURVE_ANIMATION_SPEED * curveDirection;
    if (curveFactor > MAX_CURVE_FACTOR || curveFactor < MIN_CURVE_FACTOR) {
      curveDirection *= -1;
    }
  }
}