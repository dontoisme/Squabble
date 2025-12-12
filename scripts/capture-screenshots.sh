#!/bin/bash
#
# capture-screenshots.sh
#
# Smart screenshot capture for Squabble timelapse documentation.
# Detects which screens changed based on git diff and only captures those.
#
# Usage:
#   ./scripts/capture-screenshots.sh              # Smart capture (changed screens only)
#   ./scripts/capture-screenshots.sh --baseline   # Capture ALL screens (first run)
#   ./scripts/capture-screenshots.sh --all        # Force capture all screens
#   ./scripts/capture-screenshots.sh --dry-run    # Show what would be captured
#   ./scripts/capture-screenshots.sh --screens 14,21  # Capture specific screens
#

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_FILE="$PROJECT_DIR/BookPlayer.xcodeproj"
SCHEME="BookPlayer"
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1"
SCREENSHOT_DIR="$PROJECT_DIR/Screenshots"
MANIFEST_FILE="$SCREENSHOT_DIR/manifest.json"
RESULTS_DIR="$PROJECT_DIR/TestResults"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get current git info
GIT_COMMIT=$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_COMMIT_FULL=$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}=== Squabble Screenshot Capture ===${NC}"
echo "Project: $PROJECT_DIR"
echo "Commit: $GIT_COMMIT"
echo ""

# Parse arguments
MODE="smart"
DRY_RUN=false
SPECIFIC_SCREENS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --baseline)
            MODE="baseline"
            shift
            ;;
        --all)
            MODE="all"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --screens)
            MODE="specific"
            SPECIFIC_SCREENS="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --baseline     Capture ALL screens (for first run)"
            echo "  --all          Force capture all screens"
            echo "  --dry-run      Show what would be captured without running"
            echo "  --screens IDS  Capture specific screens (comma-separated, e.g., 14,21)"
            echo "  --help         Show this help message"
            echo ""
            echo "Default: Smart capture - only screens with changed source files"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Check for manifest
if [ ! -f "$MANIFEST_FILE" ]; then
    echo -e "${RED}Error: manifest.json not found at $MANIFEST_FILE${NC}"
    echo "Run with --baseline to create initial screenshots."
    exit 1
fi

# Function to get screens affected by changed files
get_affected_screens() {
    local changed_files="$1"
    local affected_tests=""

    # Read manifest and find affected screens
    while IFS= read -r screen_id; do
        # Get sources for this screen
        local sources=$(jq -r ".screens[\"$screen_id\"].sources[]" "$MANIFEST_FILE" 2>/dev/null)
        local test_name=$(jq -r ".screens[\"$screen_id\"].test" "$MANIFEST_FILE" 2>/dev/null)

        # Check if any source file is in the changed files
        for source in $sources; do
            if echo "$changed_files" | grep -q "$source"; then
                if [ -n "$affected_tests" ]; then
                    affected_tests="$affected_tests,$test_name"
                else
                    affected_tests="$test_name"
                fi
                echo -e "  ${GREEN}→${NC} $screen_id (${source})"
                break
            fi
        done
    done < <(jq -r '.screens | keys[]' "$MANIFEST_FILE")

    echo "$affected_tests"
}

# Function to find last screenshot commit
get_last_screenshot_commit() {
    # Look for most recent commit folder in Screenshots
    local last_commit=""
    for dir in "$SCREENSHOT_DIR"/*/; do
        if [ -d "$dir" ]; then
            local dirname=$(basename "$dir")
            # Skip 'baseline' folder
            if [ "$dirname" != "baseline" ] && [ ${#dirname} -eq 7 ]; then
                last_commit="$dirname"
            fi
        fi
    done
    echo "$last_commit"
}

# Determine which screens to capture
TESTS_TO_RUN=""
OUTPUT_DIR=""

case "$MODE" in
    baseline)
        echo -e "${YELLOW}Mode: BASELINE (capturing all screens)${NC}"
        OUTPUT_DIR="$SCREENSHOT_DIR/baseline"
        # Run all tests
        TESTS_TO_RUN="all"
        ;;
    all)
        echo -e "${YELLOW}Mode: ALL (forcing full capture)${NC}"
        OUTPUT_DIR="$SCREENSHOT_DIR/$GIT_COMMIT"
        TESTS_TO_RUN="all"
        ;;
    specific)
        echo -e "${YELLOW}Mode: SPECIFIC (screens: $SPECIFIC_SCREENS)${NC}"
        OUTPUT_DIR="$SCREENSHOT_DIR/$GIT_COMMIT"
        # Convert screen IDs to test names
        IFS=',' read -ra SCREEN_IDS <<< "$SPECIFIC_SCREENS"
        for id in "${SCREEN_IDS[@]}"; do
            # Pad with leading zero if needed
            padded_id=$(printf "%02d" "$id")
            # Find matching screen
            test_name=$(jq -r ".screens | to_entries[] | select(.key | startswith(\"$padded_id-\")) | .value.test" "$MANIFEST_FILE" 2>/dev/null | head -1)
            if [ -n "$test_name" ] && [ "$test_name" != "null" ]; then
                if [ -n "$TESTS_TO_RUN" ]; then
                    TESTS_TO_RUN="$TESTS_TO_RUN,$test_name"
                else
                    TESTS_TO_RUN="$test_name"
                fi
            fi
        done
        ;;
    smart)
        echo -e "${YELLOW}Mode: SMART (detecting changes)${NC}"
        OUTPUT_DIR="$SCREENSHOT_DIR/$GIT_COMMIT"

        # Find what changed since last screenshot run
        LAST_COMMIT=$(get_last_screenshot_commit)
        if [ -z "$LAST_COMMIT" ]; then
            # Check for baseline
            if [ -d "$SCREENSHOT_DIR/baseline" ]; then
                echo "Comparing against baseline..."
                # Get baseline commit from metadata if exists
                if [ -f "$SCREENSHOT_DIR/baseline/metadata.json" ]; then
                    LAST_COMMIT=$(jq -r '.commit' "$SCREENSHOT_DIR/baseline/metadata.json" 2>/dev/null)
                fi
            fi
        fi

        if [ -z "$LAST_COMMIT" ] || [ "$LAST_COMMIT" == "null" ]; then
            echo -e "${RED}No previous screenshots found. Run with --baseline first.${NC}"
            exit 1
        fi

        echo "Last capture: $LAST_COMMIT"
        echo "Current: $GIT_COMMIT"
        echo ""

        # Get changed Swift files
        CHANGED_FILES=$(git -C "$PROJECT_DIR" diff --name-only "$LAST_COMMIT" HEAD -- '*.swift' 2>/dev/null || echo "")

        if [ -z "$CHANGED_FILES" ]; then
            echo -e "${GREEN}No Swift files changed since last capture.${NC}"
            exit 0
        fi

        echo "Changed files:"
        echo "$CHANGED_FILES" | while read -r file; do
            echo -e "  ${BLUE}•${NC} $file"
        done
        echo ""

        echo "Affected screens:"
        TESTS_TO_RUN=$(get_affected_screens "$CHANGED_FILES")

        if [ -z "$TESTS_TO_RUN" ]; then
            echo -e "${GREEN}No UI screens affected by changes.${NC}"
            exit 0
        fi
        ;;
esac

echo ""
echo -e "Output directory: ${BLUE}$OUTPUT_DIR${NC}"
echo ""

# Dry run - just show what would happen
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}=== DRY RUN ===${NC}"
    if [ "$TESTS_TO_RUN" == "all" ]; then
        echo "Would run: ALL screenshot tests"
    else
        echo "Would run tests: $TESTS_TO_RUN"
    fi
    echo "Would save to: $OUTPUT_DIR"
    exit 0
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
mkdir -p "$RESULTS_DIR"

# Build xcodebuild command
XCODE_CMD="xcodebuild test -project \"$PROJECT_FILE\" -scheme \"$SCHEME\" -destination \"$DESTINATION\""

if [ "$TESTS_TO_RUN" == "all" ]; then
    XCODE_CMD="$XCODE_CMD -only-testing:BookPlayerUITests/ScreenshotTests"
else
    # Build -only-testing flags for specific tests
    IFS=',' read -ra TEST_ARRAY <<< "$TESTS_TO_RUN"
    for test in "${TEST_ARRAY[@]}"; do
        XCODE_CMD="$XCODE_CMD -only-testing:BookPlayerUITests/ScreenshotTests/$test"
    done
fi

XCODE_CMD="$XCODE_CMD -resultBundlePath \"$RESULTS_DIR/screenshots_$TIMESTAMP.xcresult\""
XCODE_CMD="$XCODE_CMD PROJECT_DIR=\"$PROJECT_DIR\""
XCODE_CMD="$XCODE_CMD SCREENSHOT_OUTPUT_DIR=\"$OUTPUT_DIR\""
XCODE_CMD="$XCODE_CMD GIT_COMMIT=\"$GIT_COMMIT\""

# Run tests
echo -e "${BLUE}Building and running screenshot tests...${NC}"
echo ""

eval "$XCODE_CMD" 2>&1 | xcpretty || true

echo ""

# Move screenshots to output directory (if they went to root Screenshots folder)
if [ -d "$SCREENSHOT_DIR" ]; then
    for png in "$SCREENSHOT_DIR"/*.png; do
        if [ -f "$png" ]; then
            mv "$png" "$OUTPUT_DIR/" 2>/dev/null || true
        fi
    done
fi

# Generate metadata
METADATA_FILE="$OUTPUT_DIR/metadata.json"
SCREENSHOT_COUNT=$(ls -1 "$OUTPUT_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
CAPTURED_SCREENS=$(ls -1 "$OUTPUT_DIR"/*.png 2>/dev/null | xargs -I {} basename {} .png | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")

cat > "$METADATA_FILE" << EOF
{
  "commit": "$GIT_COMMIT",
  "commit_full": "$GIT_COMMIT_FULL",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "mode": "$MODE",
  "parent_commit": "${LAST_COMMIT:-null}",
  "captured_screens": $CAPTURED_SCREENS,
  "screenshot_count": $SCREENSHOT_COUNT
}
EOF

echo -e "${GREEN}=== Screenshot Capture Complete ===${NC}"
echo ""
echo "Screenshots saved to: $OUTPUT_DIR"
echo "Captured: $SCREENSHOT_COUNT screenshots"
echo ""

if [ -d "$OUTPUT_DIR" ]; then
    ls -la "$OUTPUT_DIR"/*.png 2>/dev/null || echo "(no screenshots found)"
fi

echo ""
echo -e "${GREEN}=== Done ===${NC}"
