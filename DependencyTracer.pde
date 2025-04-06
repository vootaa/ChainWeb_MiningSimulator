class DependencyTracer {
  private ConnectionManager connectionManager;
  private ArrayList<ArrayList<ArrayList<String>>> dependencies;  // [chainId][layer][dependency pair (format: "from-to")]
  private final int MAX_DEPTH = GRID_COUNT - 1;

  public DependencyTracer(ConnectionManager cm) {
    this.connectionManager = cm;
    this.dependencies = new ArrayList<ArrayList<ArrayList<String>>>();
    for (int i = 0; i < CHAIN_COUNT; i++) {
      ArrayList<ArrayList<String>> chainLayers = new ArrayList<ArrayList<String>>();
      for (int j = 0; j < MAX_DEPTH; j++) {
        chainLayers.add(new ArrayList<String>());
      }
      dependencies.add(chainLayers);
    }
  }

  public void initializePaths() {
    // Clear all existing dependencies
    clearAllDependencies();

    // L0: Initialize direct dependencies (including same chain)
    for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
      addDependency(chainId, 0, chainId, chainId);

      ArrayList<Connection> deps = connectionManager.getConnections(chainId);
      if (deps != null) {
        for (Connection conn : deps) {
          addDependency(chainId, 0, conn.from, conn.to);
        }
      }
    }

    // L1-L3: Calculate subsequent layer dependencies
    for (int layer = 1; layer < MAX_DEPTH; layer++) {
      for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
        for (String dep : dependencies.get(chainId).get(layer-1)) {
          int targetChain = Integer.parseInt(dep.split("-")[0]);  // Get target chain ID
          addDependency(chainId, layer, targetChain, targetChain);

          ArrayList<Connection> nextDeps = connectionManager.getConnections(targetChain);
          if (nextDeps != null) {
            for (Connection conn : nextDeps) {
              addDependency(chainId, layer, conn.from, conn.to);
            }
          }
        }
      }
    }
  }

  private boolean containsDependency(int chainId, int layer, String dependency) {
    return dependencies.get(chainId).get(layer).contains(dependency);
  }

  private void addDependency(int chainId, int layer, int from, int to) {
    String dependency = String.format("%d-%d", from, to);
    if (!containsDependency(chainId, layer, dependency)) {
      dependencies.get(chainId).get(layer).add(dependency);
    }
  }

  private void clearAllDependencies() {
    for (int i = 0; i < CHAIN_COUNT; i++) {
      for (int j = 0; j < MAX_DEPTH; j++) {
        dependencies.get(i).get(j).clear();
      }
    }
  }

  public ArrayList<Connection> getDependencyPathsForLayer(int chainId, int layer) {
    ArrayList<Connection> deps = new ArrayList<Connection>();
    for (String dep : dependencies.get(chainId).get(layer)) {
      String[] parts = dep.split("-");
      int to = Integer.parseInt(parts[1]);
      ArrayList<Connection> conns = connectionManager.getConnections(to);
      if (conns != null) {
        deps.addAll(conns);
      }
    }
    return deps;
  }

  public void printDebugInfo() {
    println("\n=== Dependency Analysis ===");

    for (int chainId = 0; chainId < CHAIN_COUNT; chainId++) {
      println(String.format("\nChain %d Dependencies:", chainId));
      println("Layer | Dependencies <from,to>              | Checked | Unchecked List");
      println("-".repeat(75));

      ArrayList<Boolean> checked = new ArrayList<Boolean>();
      for (int i = 0; i < CHAIN_COUNT; i++) {
        checked.add(false);
      }

      for (int layer = 0; layer < MAX_DEPTH; layer++) {
        ArrayList<String> layerDeps = dependencies.get(chainId).get(layer);
        String depsStr = String.join(", ", layerDeps);

        ArrayList<Integer> uncheckedNodes = new ArrayList<Integer>();
        for (String dep : layerDeps) {
          String[] parts = dep.split("-");
          int from = Integer.parseInt(parts[0]);
          if (!checked.get(from)) {
            checked.set(from, true);
          }
        }

        // Calculate the number of checked nodes
        int checkedCount = 0;
        for (int idx = 0; idx < CHAIN_COUNT; idx++) {
          if (!checked.get(idx)) {
            uncheckedNodes.add(idx);
          } else {
            checkedCount++;
          }
        }

        // Build unchecked nodes string
        String uncheckedStr = uncheckedNodes.isEmpty() ? "---" :
          uncheckedNodes.toString().replaceAll("[\\[\\]]", "");

        // Print current layer information
        String layerInfo = String.format("L%-3d | %-35s | %3d/%d  | %s",
          layer,
          depsStr.isEmpty() ? "---" : depsStr,
          checkedCount,
          CHAIN_COUNT,
          uncheckedStr
          );
        println(layerInfo);
      }

      println("-".repeat(75));
    }
    println("=== End Analysis ===\n");
  }
}
