class ConnectionManager {
  private ArrayList<ArrayList<Connection>> connections;    // Only store curve dependency connections
  private ArrayList<Connection> activeConnections;        // Currently active dependency connections
  private color[] colors;                                // Connection color array
  private Block currentMiningBlock;                      // Currently mining block
  private BlockManager blockManager;

  ConnectionManager(BlockManager blockManager) {
    this.blockManager = blockManager;
    connections = new ArrayList<ArrayList<Connection>>();
    activeConnections = new ArrayList<Connection>();
    initializeColors();
    generateConnections();
  }

  private void initializeColors() {
    colors = new color[] {
      color(255, 102, 102), // Red series - First group +5
      color(255, 178, 102), // Orange - First group +10
      color(255, 255, 102), // Yellow - First group +15
      color(153, 255, 153), // Green series - Second group
      color(102, 178, 255)  // Blue series - Third group
    };
  }

  private void generateConnections() {
    // Initialize outer ArrayList
    for (int i = 0; i < CHAIN_COUNT; i++) {
      connections.add(new ArrayList<Connection>());
    }

    // Generate three groups of connections
    generateFirstGroupConnections();  // +5, +10, +15 connections
    generateSecondGroupConnections(); // 5-9 nodes loop +2 connections
    generateThirdGroupConnections();  // 10-19 nodes loop +1 connection
  }

  private void generateFirstGroupConnections() {
    for (int i = 0; i < 5; i++) {
      // +5 connection
      addConnection(i, (i + 5) % CHAIN_COUNT, 0);
      // +10 connection
      addConnection(i, (i + 10) % CHAIN_COUNT, 1);
      // +15 connection
      addConnection(i, (i + 15) % CHAIN_COUNT, 2);
    }
  }

  private void generateSecondGroupConnections() {
    for (int i = 5; i < 10; i++) {
      int target = (i - 5 + 2) % 5 + 5;
      addConnection(i, target, 3);
    }
  }

  private void generateThirdGroupConnections() {
    for (int i = 10; i < 20; i++) {
      int target = (i == 19) ? 10 : i + 1;
      addConnection(i, target, 4);
    }
  }

  private void addConnection(int from, int to, int colorIndex) {
    connections.get(to).add(new Connection(from, to, colors[colorIndex]));
    connections.get(from).add(new Connection(to, from, colors[colorIndex]));     // Add reverse connection
  }

  Block getCurrentMiningBlock() {
    return currentMiningBlock;
  }

  void activateConnections(Block block) {
    currentMiningBlock = block;
    activeConnections.clear();
    ArrayList<Connection> blockConnections = connections.get(block.chainId);
    if (blockConnections != null) {
      activeConnections.addAll(blockConnections);
    }

    drawAnimController.reset(); // Reset animation controller
  }

  ArrayList<Connection> getConnections(int chainId) {
    return connections.get(chainId);
  }

  ArrayList<Connection> getActiveConnections() {
    return activeConnections;
  }

  boolean checkDependencies(Block block) {
    if (block.height == STATIC_BLOCK_COUNT+1) return true; // First layer has no dependencies

    // Check previous block on the same chain
    Block prevBlock = blockManager.getBlock(block.chainId, block.height - 1);
    if (prevBlock == null || prevBlock.state != BlockState.MINED) {
      return false;
    }

    // Check cross-chain dependencies
    ArrayList<Connection> deps = connections.get(block.chainId);
    if (deps == null || deps.isEmpty()) return false;

    for (Connection conn : deps) {
      Block depBlock = blockManager.getBlock(conn.from, block.height - 1);
      if (depBlock == null || depBlock.state != BlockState.MINED) {
        return false;
      }
    }

    return true;
  }
}
