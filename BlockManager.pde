import java.util.Map;

class BlockManager {
  private HashMap<String, Block> blocks;  // key: "chainId_height"

  BlockManager() {
    blocks = new HashMap<>();
    initializeBlocks();
  }

  private void initializeBlocks() {
    // Initialize static blocks (STATIC_BLOCK_COUNT layers)
    for (int height = 1; height <= STATIC_BLOCK_COUNT; height++) {
      for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
        Block block = new Block(chainId, height);
        block.state = BlockState.MINED;
        blocks.put(getBlockKey(chainId, height), block);
      }
    }

    // Initialize dynamic blocks (last three layers)
    for (int height = STATIC_BLOCK_COUNT + 1; height <= GRID_COUNT; height++) {
      for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
        Block block = new Block(chainId, height);
        blocks.put(getBlockKey(chainId, height), block);
      }
    }
  }

  void update(float deltaTime) {
    for (Block block : blocks.values()) {
      block.update(deltaTime);
    }
  }

  void shiftBlocksLeft() {
    HashMap<String, Block> newBlocks = new HashMap<>();
    // Shift all blocks one position to the left
    for (int height = 2; height <= GRID_COUNT; height++) {
      for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
        Block block = getBlock(chainId, height);
        if (block != null) {
          block.height--;
          block.updatePositionWithGrid();
          newBlocks.put(getBlockKey(chainId, block.height), block);
        }
      }
    }

    blocks = newBlocks;

    // Initialize new blocks for the last layer
    for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
      createBlock(chainId, GRID_COUNT);
    }
  }

  Block getBlock(int chainId, int height) {
    return blocks.get(getBlockKey(chainId, height));
  }

  private void createBlock(int chainId, int height) {
    Block block = new Block(chainId, height);
    block.state = BlockState.UNMINED;
    blocks.put(getBlockKey(chainId, height), block);
  }


  private String getBlockKey(int chainId, int height) {
    return chainId + "_" + height;
  }

  ArrayList<Block> getMinableBlocks() {
    ArrayList<Block> minableBlocks = new ArrayList<>();
    for (int height = STATIC_BLOCK_COUNT + 1; height <= GRID_COUNT; height++) {
      for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
        Block block = getBlock(chainId, height);
        if (block != null && block.state == BlockState.UNMINED &&
          connectionManager.checkDependencies(block)) {
          minableBlocks.add(block);
        }
      }
    }
    return minableBlocks;
  }
}
