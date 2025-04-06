static final float[] ANGLES = {288, 0, 72, 144, 216, 288, 0, 72, 144, 216, 278, 10, 62, 154, 206, 298, 350, 82, 134, 226};
static HashMap<Integer, PVector> positionCache = new HashMap<Integer, PVector>(); // Static HashMap to store calculation results

/**
 * Calculate the position of a block in 3D graph mode
 * @param chainId Chain ID (0-19)
 * @return PVector Vector containing x, y coordinates
 */

PVector calculateGraphPosition(int chainId) {
  // Check if the result is already in the cache
  if (positionCache.containsKey(chainId)) {
    return positionCache.get(chainId);
  }

  // Check input validity
  if (chainId < 0 || chainId >= CHAIN_COUNT || chainId >= ANGLES.length) {
    println("Error: Invalid chainId: " + chainId);
    return new PVector(0, 0);
  }

  // Determine radius based on chainId
  float radius;
  if (chainId >= 5 && chainId < 10) {
    radius = GRAPH_INNER_RADIUS;  // Inner radius (5-9)
  } else if (chainId >= 0 && chainId < 5) {
    radius = GRAPH_MIDDLE_RADIUS; // Middle radius (0-4)
  } else {
    radius = GRAPH_OUTER_RADIUS;  // Outer radius (10-19)
  }
  
  // Get predefined angle (convert to radians)
  float angle = radians(ANGLES[chainId]);
  
  // Convert polar coordinates to Cartesian coordinates (x, y)
  PVector position = new PVector(
    radius * cos(angle),
    radius * sin(angle)
  );
  
  // Store the result in the cache
  positionCache.put(chainId, position);
  
  return position;
}

float getAngleByChainId(int chainId) {
  return radians(ANGLES[chainId]);
}