class MiningSimulator {
  private BlockManager blockManager;
  private ConnectionManager connectionManager;
  private LayerManager layerManager;
  private Metrics metrics;
  private float miningTimer;
  private boolean isMining;
  private Block currentMiningBlock;

  MiningSimulator(BlockManager blockManager, ConnectionManager connectionManager, LayerManager layerManager) {
    this.blockManager = blockManager;
    this.connectionManager = connectionManager;
    this.layerManager = layerManager;
    this.metrics = layerManager.getMetrics();
    this.miningTimer = 0;
    this.isMining = false;
    this.currentMiningBlock = null;
    MINING_START_TIME = millis() / 1000.0;
  }

  void update(float deltaTime) {
    if (!isMining) {
      // Get the list of minable blocks
      ArrayList<Block> minableBlocks = blockManager.getMinableBlocks();
      if (!minableBlocks.isEmpty()) {
        // Randomly select a minable block
        Block selectedBlock = minableBlocks.get(floor(random(minableBlocks.size())));
        startMining(selectedBlock);
      }
    } else {
      miningTimer -= deltaTime;
      if (miningTimer <= 0) {
        finishMining();
      }
    }
  }

  private void finishMining() {
    if (currentMiningBlock != null) {
      isMining = false;
      currentMiningBlock.state = BlockState.MINED;
      metrics.onBlockMined(currentMiningBlock.chainId);

      layerManager.drawInfoLayer();
      if (!layerManager.isShifting) {
        layerManager.checkAndStartShift();
      }

      currentMiningBlock = null;
    }
  }

  private void startMining(Block block) {
    currentMiningBlock = block;
    isMining = true;
    miningTimer = random(MIN_MINING_TIME, MAX_MINING_TIME);
    block.state = BlockState.MINING;
    block.miningDuration = miningTimer;
    metrics.onBlockMining(currentMiningBlock);
    connectionManager.activateConnections(currentMiningBlock);
    layerManager.drawInfoLayer();
  }
}
