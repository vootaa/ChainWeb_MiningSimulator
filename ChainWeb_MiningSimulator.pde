BlockManager blockManager;
ConnectionManager connectionManager;
LayerManager layerManager;
MiningSimulator miningSimulator;
DependencyTracer dependencyTracer;
DrawAnimationController drawAnimController;
CurveAnimationController curveController;

void setup() {
  size(1280, 720, P2D);
  frameRate(30);
  smooth(4);

  initializeFonts();

  blockManager = new BlockManager();
  connectionManager = new ConnectionManager(blockManager);
  drawAnimController = new DrawAnimationController();
  curveController = new CurveAnimationController();
  layerManager = new LayerManager(blockManager, connectionManager, drawAnimController);
  miningSimulator = new MiningSimulator(blockManager, connectionManager, layerManager);

  // Initialize dependency tracker and precompute all paths
  dependencyTracer = new DependencyTracer(connectionManager);  
  dependencyTracer.initializePaths();
  //dependencyTracer.printDebugInfo();  // Print detailed dependency information
}

void initializeFonts() {
  tinyFont = loadFont("KodeMono-Regular-10.vlw");
  smallFont = loadFont("KodeMono-Medium-12.vlw");
  normalFont = loadFont("KodeMono-SemiBold-14.vlw");
  largeFont = loadFont("KodeMono-Bold-16.vlw");
}

void draw() {
  float deltaTime = 1.0 / frameRate;

  miningSimulator.update(deltaTime); // Update simulator
  blockManager.update(deltaTime); // Update block state
  layerManager.update(deltaTime); // Update layer manager
  drawAnimController.update(deltaTime); // Update animation controller

  // Draw all layers
  layerManager.draw();

  //saveFrame(10000,12000);
}

void keyPressed() {
  if (key == ' ') {  // Space key to toggle mode
    layerManager.taggleDisplayMode();
  }
  if (key == 'P' || key == 'p') {
    layerManager.taggleShowPetersenGraph();
  }
}

void mouseWheel(MouseEvent event) {
  // Check if the current display mode is 3D graph mode
  if (layerManager != null && layerManager.getCurrentMode() == DisplayMode.GRAPH) {
    float e = event.getCount();
    // Scrolling up makes e negative, scrolling down makes e positive
    // Scroll up to zoom in, scroll down to zoom out
    layerManager.adjustGraph3DScale(-e * 0.005); // Adjust coefficient as needed
  }
}
