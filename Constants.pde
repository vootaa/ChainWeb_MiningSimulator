enum DisplayMode {
  WEAVE,   // Weave mode
  XCHAIN,  // Cross-chain mode
  GRAPH  // Graph mode
}

// Global font variables
PFont tinyFont,smallFont, normalFont, largeFont;

// Window and layout
static final int WINDOW_WIDTH = 1280;
static final int WINDOW_HEIGHT = 720;
static final int CHAIN_COUNT = 20;
static final int GRID_COUNT = 5;

// Block state related
static final int DYNAMIC_BLOCK_COUNT = 3;   // Number of dynamic blocks
static final int STATIC_BLOCK_COUNT = GRID_COUNT - DYNAMIC_BLOCK_COUNT;   // Number of static blocks

// Layout margins and areas
static final int MARGIN_LEFT = 20;           // Left margin
static final int MARGIN_RIGHT = 20;          // Right margin
static final int MARGIN_TOP = 80;            // Top information area height
static final int MARGIN_BOTTOM = 20;         // Bottom margin
static final int LABEL_WIDTH = 40;           // Chain ID label area width
static final int LABEL_PADDING = 10;         // Label padding

// Grid calculation (dynamically calculated based on available space)
static final float GRID_WIDTH = (WINDOW_WIDTH - MARGIN_LEFT - MARGIN_RIGHT - LABEL_WIDTH) / GRID_COUNT;
static final float CONTENT_HEIGHT = WINDOW_HEIGHT - MARGIN_TOP - MARGIN_BOTTOM;
static final float ROW_HEIGHT = CONTENT_HEIGHT / CHAIN_COUNT;

final float METRICS_PADDING = 10;
final float Mining_INDICATOR_PADDING = 10;
final float Mode_INDICATOR_WIDTH = 60;

// Block size
static final float BLOCK_SIZE = 20;
static final float ARROW_SIZE = 10;

// Mining related
static final float MIN_MINING_TIME = 0.8;
static final float MAX_MINING_TIME = 2.2;
static float MINING_START_TIME = 0;

static final float CONNECTION_LINE_DELAY = 0.3;
static final float CURVED_LINE_DELAY = 0.8;

// Unified dark theme color scheme
// Base colors
final color BG_COLOR = color(17, 23, 26);        // Darker background color
final color LABEL_COLOR = color(236, 240, 241);  // Clearer label text
final color GRID_COLOR = color(44, 62, 80);      // Softer grid lines

// Connection line colors
final color CONNECTION_LINE_COLOR = color(52, 152, 219); // Bright blue
final color ARROW_COLOR = color(41, 128, 185);           // Dark blue arrow

// Block state colors
final color UNMINED_COLOR = color(52, 73, 94);          // Unmined state
final color MINING_COLOR = color(230, 126, 34);         // Mining state (orange)
final color MINED_COLOR = color(46, 204, 113);          // Mined state (green)

// Block height related
final static int START_BLOCK_HEIGHT = 5581278;
static int CURRENT_BLOCK_HEIGHT = START_BLOCK_HEIGHT;  // Current block height

// Metrics display related colors
final color METRICS_BG_COLOR = color(44, 62, 80, 220);      // Semi-transparent dark background
final color METRICS_TEXT_COLOR = color(236, 240, 241);      // Clear text color
final color METRICS_WARNING_COLOR = color(231, 76, 60);     // Warning color (bright red)
final color METRICS_SUCCESS_COLOR = color(46, 204, 113);    // Success color (green)
final color METRICS_HIGHLIGHT_COLOR = color(241, 196, 15);  // Highlight color (golden yellow)
final color METRICS_GRID_COLOR = color(52, 73, 94, 180);    // Semi-transparent grid lines

// Chart color supplement
final color METRICS_AXIS_COLOR = color(189, 195, 199);      // Axis color
final color METRICS_POINT_COLOR = color(241, 196, 15);      // Data point color
final color METRICS_VALUE_COLOR = color(255, 107, 107);      // Value curve (coral red)
final color METRICS_AVG_LINE_COLOR = color(168, 230, 207);  // Average line color (mint green)
final color METRICS_CURRENT_COLOR = color(52, 152, 219);    // Current value color

// Status indicator colors
final color STATUS_NORMAL = color(46, 204, 113);    // Normal status
final color STATUS_WARNING = color(241, 196, 15);   // Warning status
final color STATUS_ERROR = color(231, 76, 60);      // Error status

// Chart transparency
final int CHART_ALPHA = 220;                // Chart base transparency
final int GRID_ALPHA = 180;                 // Grid line transparency
final int HOVER_ALPHA = 250;                // Hover state transparency

// XCHAIN mode connection line constants
final float DOT_MARGIN = BLOCK_SIZE * 0.5;  // End margin distance
final float BASE_DOT_SIZE = 4;          // Base dot size
final float BASE_DOT_SPACING = 10;      // Base dot spacing
final color BASE_DOT_COLOR = color(50);
final color ART_DOT_COLOR = color(255, 255, 255, 180);  // Transparent bright cyan

// Bezier curve animation parameters
final float CURVE_ANIMATION_SPEED = 0.01;    // Curve animation speed
final float MIN_CURVE_FACTOR = 0.15;         // Minimum curvature factor
final float MAX_CURVE_FACTOR = 0.25;         // Maximum curvature factor

// GRAPH layout
static final float GRAPH_INNER_RADIUS = 100;
static final float GRAPH_MIDDLE_RADIUS = 200;
static final float GRAPH_OUTER_RADIUS = 290;

// 3D mode concentric circle colors (with transparency) - Green series
final color GRAPH_CIRCLE_COLOR = color(0, 100, 0, 180);      // Dark green
final color GRAPH_Petersen_CIRCLE_COLOR = color(44, 62, 80, 180);     // Dark gray
final color GRAPH_Petersen_LINE_COLOR = color(96, 125, 139, 180);   // Medium gray
final color GRAPH_LABEL_COLOR = color(200);
final color GRAPH_HEIGHT_LABEL_COLOR = color(120);