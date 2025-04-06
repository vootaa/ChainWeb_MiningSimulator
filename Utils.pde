String formatNumber(int x) {
  // Add commas to separate every three digits
  String str = String.valueOf(x);
  StringBuilder formatted = new StringBuilder();
  int count = 0;

  for (int i = str.length() - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) {
      formatted.insert(0, ',');
    }
    formatted.insert(0, str.charAt(i));
    count++;
  }

  return formatted.toString();
}

String formatTime(float seconds) {
  // Format time in HH:MM:SS format
  int totalSeconds = (int)seconds;
  int hours = totalSeconds / 3600;
  int minutes = (totalSeconds % 3600) / 60;
  int secs = totalSeconds % 60;
  return String.format("%02d:%02d:%02d", hours, minutes, secs);
}

void saveFrame(int start, int end) {
  // Save frames within the specified range
  if (frameCount >= start && frameCount < end) {
    saveFrame("frames/frame-####.png");
    println("Saving frame: " + frameCount);
  }

  if (frameCount == end) {
    println("Save Frame Completed.");
  }
}
