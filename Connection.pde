class Connection {
  int from;           // Source node chain ID
  int to;             // Target node chain ID
  color lineColor;    // Connection line color

  Connection(int from, int to, color lineColor) {
    this.from = from;
    this.to = to;
    this.lineColor = lineColor;
  }
}
