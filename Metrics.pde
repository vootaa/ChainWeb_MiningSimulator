class Metrics {
  private MiningIndicator[] indicators;
  private BlockManager blockManager;

  private float lastBlockSectionMinedTime = 0;
  private float lastBlockMinedTime = 0;
  private float blockSectionMinedInterval = 0;
  private float blockMinedInterval = 0;
  private int totalMinedBlockSection = 0;
  private int totalMinedBlocks = 0;
  private float avgBlockSectionMinedTime = 0;
  private float avgBlockMinedTime = 0;
  private Block currentMiningBlock;

  private float[] chainPrevMineTime;
  private float[] chainCurrentMineTime;

  private ArrayList<Float> blockTimeHistory = new ArrayList<Float>();
  private ArrayList<Float> chainTimeDiffHistory = new ArrayList<Float>();
  private ArrayList<Float> sectionTimeHistory = new ArrayList<Float>();
  private static final int MAX_HISTORY_POINTS = 50;  // Save the latest 50 data points

  private float infoTextWidth = 0;
  private float infoTextHeight = 0;

  Metrics(BlockManager blockManager) {
    this.blockManager = blockManager;
    this.indicators = new MiningIndicator[3];  // 3 block height indicators
    for (int i = 0; i < 3; i++) {
      this.indicators[i] = new MiningIndicator();
    }
    chainPrevMineTime = new float[CHAIN_COUNT];
    chainCurrentMineTime = new float[CHAIN_COUNT];
    for (int i = 0; i < CHAIN_COUNT; i++) {
      chainPrevMineTime[i] = 0;
      chainCurrentMineTime[i] = 0;
    }
  }

  void onBlockMining(Block block) {
    this.currentMiningBlock = block;
  }

  void onBlockMined(int chainId) {
    totalMinedBlocks++;
    float currentTime = millis() / 1000.0;

    // Record the time difference on the chain
    chainPrevMineTime[chainId] = chainCurrentMineTime[chainId];
    chainCurrentMineTime[chainId] = currentTime;

    // Record the time difference on the chain and add it to the history
    float timeDiff = chainCurrentMineTime[chainId] - chainPrevMineTime[chainId];
    if (timeDiff > 0) {
        chainTimeDiffHistory.add(timeDiff);
        if (chainTimeDiffHistory.size() > MAX_HISTORY_POINTS) {
          chainTimeDiffHistory.remove(0);
        }
    }

    // Calculate the time interval between any two adjacent mined blocks
    blockMinedInterval = (lastBlockMinedTime > 0) ? (currentTime - lastBlockMinedTime) : 0;
    lastBlockMinedTime = currentTime;

    // Calculate the average block mining time
    if (MINING_START_TIME > 0 && totalMinedBlocks > 0) {
      avgBlockMinedTime = (currentTime - MINING_START_TIME) / totalMinedBlocks;
    }

    if (blockMinedInterval > 0) {
      blockTimeHistory.add(blockMinedInterval);
      if (blockTimeHistory.size() > MAX_HISTORY_POINTS) {
        blockTimeHistory.remove(0);
      }
    }
  }

  void onShift() {
    float currentTime = millis() / 1000.0;

    // Calculate the block layer completion time (all 20 chains complete the current height)
    blockSectionMinedInterval = (lastBlockSectionMinedTime > 0) ? (currentTime - lastBlockSectionMinedTime) : 0;

    // Calculate the block height increment and average time
    totalMinedBlockSection = CURRENT_BLOCK_HEIGHT - START_BLOCK_HEIGHT;
    if (MINING_START_TIME > 0 && totalMinedBlockSection > 0) {
      avgBlockSectionMinedTime = (currentTime - MINING_START_TIME) / totalMinedBlockSection;
    }

    lastBlockSectionMinedTime = currentTime;

    if (blockSectionMinedInterval > 0) {
      sectionTimeHistory.add(blockSectionMinedInterval);
      if (sectionTimeHistory.size() > MAX_HISTORY_POINTS) {
        sectionTimeHistory.remove(0);
      }
    }
  }

  void draw(PGraphics pg) {
    if (pg == null) return;

    drawInfoPanel(pg);
    drawChainTimeDiffs(pg);
    drawMiningIndicators(pg);
  }

  float getInfoTextWidth(){
    return this.infoTextWidth;
  }

  float getInfoTextHeight(){
    return (this.infoTextHeight > 0) ? this.infoTextHeight : 14;
  }

  private void drawInfoPanel(PGraphics pg) {
    pg.noStroke();
    pg.textFont(smallFont);
    pg.textAlign(LEFT, CENTER);

    float runTime = millis() / 1000.0 - MINING_START_TIME;

    String info = String.format("+ %d Blocks Mined: %.2f/%.3f s, + %d Block Height: %.2f/%.2f s  %s  ",
      totalMinedBlocks, blockMinedInterval, avgBlockMinedTime,
      totalMinedBlockSection, blockSectionMinedInterval, avgBlockSectionMinedTime, formatTime(runTime));

    infoTextWidth = pg.textWidth(info);
    infoTextHeight = pg.textAscent() + pg.textDescent();  // Calculate actual text height
    float boxPadding = METRICS_PADDING * 2;  // Leave padding on both sides
    float boxWidth = infoTextWidth + boxPadding; // Background box width
    float boxHeight = infoTextHeight + boxPadding;  // Background box height
    float y = METRICS_PADDING + boxHeight/2;  // Text vertical center position

    // Draw background box
    pg.fill(METRICS_BG_COLOR);
    pg.stroke(METRICS_AXIS_COLOR);
    pg.strokeWeight(1);
    pg.rect(MARGIN_LEFT, y - boxHeight/2, boxWidth, boxHeight);

    pg.fill(METRICS_HIGHLIGHT_COLOR);
    pg.text(info, MARGIN_LEFT + METRICS_PADDING, y);

    // Draw current chain information
    String chainInfo = currentMiningBlock == null ? "" : "C" + currentMiningBlock.chainId;
    pg.textFont(normalFont);
    pg.textAlign(RIGHT, CENTER);
    pg.fill(MINING_COLOR);
    pg.text(chainInfo, WINDOW_WIDTH - MARGIN_RIGHT, MARGIN_TOP - LABEL_PADDING);

    // Draw trend graphs
    float graphX = MARGIN_LEFT + boxWidth + Mode_INDICATOR_WIDTH + METRICS_PADDING * 4;
    float graphY = METRICS_PADDING;
    float availableWidth = WINDOW_WIDTH - graphX - MARGIN_RIGHT;
    float graphWidth = (availableWidth - METRICS_PADDING * 4) / 3;  // Divide equally among three graphs
    float graphHeight = boxHeight;

    // Draw block mining interval trend graph
    drawTimeGraph(pg, "Block Mining Interval", blockTimeHistory,
      graphX, graphY, graphWidth, graphHeight,
      blockMinedInterval, avgBlockMinedTime);

    // Draw chain mining interval trend graph
    drawTimeGraph(pg, "Chain Mining Interval", chainTimeDiffHistory,
      graphX + graphWidth + METRICS_PADDING * 2, graphY, graphWidth, graphHeight,
      getLatestChainTimeDiff(), getAvgChainTimeDiff());

    // Draw block height interval trend graph
    drawTimeGraph(pg, "Block Height Interval", sectionTimeHistory,
      graphX + (graphWidth + METRICS_PADDING * 2) * 2, graphY, graphWidth, graphHeight,
      blockSectionMinedInterval, avgBlockSectionMinedTime);
  }

  private void drawChainTimeDiffs(PGraphics pg) {
    float timeX = MARGIN_LEFT + LABEL_WIDTH + 10;
    float graphX = WINDOW_WIDTH - MARGIN_RIGHT;
    float maxGraphWidth = GRID_WIDTH * 0.3;  // Maximum graph width
    float maxTime = 30.0;  // Reference time for normalization

    pg.textFont(smallFont);
    pg.textAlign(LEFT, CENTER);

    // Find the maximum time difference for dynamic scaling
    float maxTimeDiff = 0;
    for (int i = 0; i < CHAIN_COUNT; i++) {
      float timeDiff = chainCurrentMineTime[i] - chainPrevMineTime[i];
      if (timeDiff > maxTimeDiff) maxTimeDiff = timeDiff;
    }
    // Dynamically adjust maxTime
    maxTime = max(30.0, maxTimeDiff);

    for (int i = 0; i < CHAIN_COUNT; i++) {
      float timeDiff = chainCurrentMineTime[i] - chainPrevMineTime[i];
      float rowY = MARGIN_TOP + (i * ROW_HEIGHT) + (ROW_HEIGHT / 2);

      // Calculate text and background box dimensions
      String txt = String.format("%.2fs", timeDiff > 0 ? timeDiff : 0);
      float textWidth = pg.textWidth(txt);
      float boxHeight = pg.textAscent() + pg.textDescent() + METRICS_PADDING;

      // Choose color based on time difference
      color bgColor = (timeDiff > 30.0) ? METRICS_WARNING_COLOR : METRICS_SUCCESS_COLOR;
      // Handle transparency
      bgColor = color(red(bgColor), green(bgColor), blue(bgColor), CHART_ALPHA);

      // Draw background
      pg.noStroke();
      pg.fill(bgColor);
      pg.rect(timeX - METRICS_PADDING,
        rowY - boxHeight/2,
        textWidth + METRICS_PADDING * 2,
        boxHeight);

      // Draw text
      pg.fill(METRICS_TEXT_COLOR);
      pg.text(txt, timeX, rowY);

      // Draw graph part
      // Calculate bar width
      float barWidth = map(timeDiff, 0, maxTime, 0, maxGraphWidth);
      float barHeight = ROW_HEIGHT * 0.4;  // Bar height is 50% of row height

      // Draw background
      pg.fill(METRICS_BG_COLOR);
      pg.rect(graphX - maxGraphWidth,
        rowY - barHeight/2,
        maxGraphWidth,
        barHeight);

      // Draw time bar
      pg.fill(bgColor);
      pg.rect(graphX - barWidth,
        rowY - barHeight/2,
        barWidth,
        barHeight);
    }
  }

  private void drawTimeGraph(PGraphics pg, String title, ArrayList<Float> history,
    float x, float y, float w, float h,
    float currentValue, float avgValue) {
    // Draw background
    pg.fill(METRICS_BG_COLOR);
    pg.noStroke();
    pg.rect(x, y, w, h);

    // Calculate maximum value
    float maxVal = avgValue;  // Start from average value
    if (history.size() > 0) {
      for (Float value : history) {
        if (value > maxVal) maxVal = value;
      }
    }
    maxVal = max(maxVal, currentValue);  // Ensure current value is considered

    // Draw grid lines
    pg.stroke(METRICS_GRID_COLOR);
    pg.strokeWeight(1);
    for (int i = 1; i < 4; i++) {
      float gridY = map(i, 0, 4, y + h - 4, y + 14);
      pg.line(x + 2, gridY, x + w - 2, gridY);
    }

    // Draw average value line
    if (avgValue > 0) {
      pg.stroke(METRICS_AVG_LINE_COLOR);
      pg.strokeWeight(1);
      float avgY = map(avgValue, 0, maxVal, y + h - 4, y + 14);
      pg.line(x + 2, avgY, x + w - 2, avgY);
    }

    // Draw trend line
    if (history.size() > 1) {
      pg.stroke(METRICS_VALUE_COLOR);
      pg.strokeWeight(1);
      pg.noFill();
      pg.beginShape();

      for (int i = 0; i < history.size(); i++) {
        float px = map(i, 0, history.size()-1, x + 2, x + w - 2);
        float py = map(history.get(i), 0, maxVal, y + h - 4, y + 14);
        pg.vertex(px, py);
      }
      pg.endShape();

      // Mark the latest point
      pg.fill(METRICS_POINT_COLOR);
      pg.noStroke();
      float lastX = x + w - 2;
      float lastY = map(history.get(history.size()-1), 0, maxVal, y + h - 4, y + 14);
      pg.circle(lastX, lastY, 6);
    }

    // Draw title and values
    pg.textFont(tinyFont);
    pg.textAlign(LEFT, TOP);
    pg.fill(METRICS_TEXT_COLOR);
    pg.text(title, x + 4, y + 4);

    pg.textAlign(RIGHT, TOP);
    pg.fill(METRICS_CURRENT_COLOR);
    pg.text(String.format("%.2fs", currentValue), x + w - 4, y + 4);

    pg.fill(METRICS_AVG_LINE_COLOR);
    pg.text(String.format("avg:%.2fs", avgValue), x + w - 4, y + h - 16);

    // Draw border
    pg.noFill();
    pg.stroke(METRICS_AXIS_COLOR);
    pg.strokeWeight(1);
    pg.rect(x, y, w, h);
  }

  private float getLatestChainTimeDiff() {
    return chainTimeDiffHistory.size() > 0 ? chainTimeDiffHistory.get(chainTimeDiffHistory.size() - 1) : 0;
  }

  private float getAvgChainTimeDiff() {
    if (chainTimeDiffHistory.size() == 0) return 0;
    
    float sum = 0;
    for (Float diff : chainTimeDiffHistory) {
      sum += diff;
    }
    return sum / chainTimeDiffHistory.size();
  }

  private void drawMiningIndicators(PGraphics pg) {
    float startX = MARGIN_LEFT + LABEL_WIDTH + GRID_WIDTH * STATIC_BLOCK_COUNT + Mining_INDICATOR_PADDING;
    float startY = (MARGIN_TOP - LABEL_PADDING) - 10;

    for (int i = 0; i < DYNAMIC_BLOCK_COUNT; i++) {
      int blockHeight =  STATIC_BLOCK_COUNT + (i + 1); // Block height starts from 1
      float indicatorX = startX + i * GRID_WIDTH;

      indicators[i].setPosition(indicatorX, startY);
      indicators[i].draw(pg, blockManager, blockHeight);
    }
  }
}
