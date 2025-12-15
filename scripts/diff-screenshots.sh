#!/bin/bash
#
# diff-screenshots.sh
#
# Compare screenshots between two commits/directories and generate a visual diff report.
# Uses ImageMagick for pixel-based comparison.
#
# Usage:
#   ./scripts/diff-screenshots.sh                    # Compare latest vs baseline
#   ./scripts/diff-screenshots.sh <commit1> <commit2> # Compare two specific commits
#   ./scripts/diff-screenshots.sh --html             # Generate HTML report
#

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCREENSHOT_DIR="$PROJECT_DIR/Screenshots"
DIFF_OUTPUT_DIR="$SCREENSHOT_DIR/diff"
MANIFEST_FILE="$SCREENSHOT_DIR/manifest.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Thresholds
DIFF_THRESHOLD=0.01  # Percent difference to consider "changed"
SIGNIFICANT_THRESHOLD=5  # Percent difference to highlight as significant

echo -e "${BLUE}=== Screenshot Diff Tool ===${NC}"
echo ""

# Parse arguments
GENERATE_HTML=false
COMMIT1=""
COMMIT2=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --html)
            GENERATE_HTML=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS] [commit1] [commit2]"
            echo ""
            echo "Options:"
            echo "  --html    Generate HTML report with visual diffs"
            echo "  --help    Show this help"
            echo ""
            echo "Arguments:"
            echo "  commit1   First commit/directory (default: baseline)"
            echo "  commit2   Second commit/directory (default: latest)"
            exit 0
            ;;
        *)
            if [ -z "$COMMIT1" ]; then
                COMMIT1="$1"
            elif [ -z "$COMMIT2" ]; then
                COMMIT2="$1"
            fi
            shift
            ;;
    esac
done

# Check for ImageMagick
if ! command -v compare &> /dev/null; then
    echo -e "${YELLOW}Warning: ImageMagick not found. Install with: brew install imagemagick${NC}"
    echo "Falling back to file size comparison only."
    USE_IMAGEMAGICK=false
else
    USE_IMAGEMAGICK=true
fi

# Find directories to compare
find_latest_capture() {
    # Find most recent directory (by name, excluding baseline and diff)
    ls -1d "$SCREENSHOT_DIR"/*/ 2>/dev/null | \
        grep -v baseline | grep -v diff | \
        sort -r | head -1 | xargs basename 2>/dev/null || echo ""
}

if [ -z "$COMMIT1" ]; then
    COMMIT1="baseline"
fi

if [ -z "$COMMIT2" ]; then
    COMMIT2=$(find_latest_capture)
    if [ -z "$COMMIT2" ]; then
        echo -e "${RED}Error: No screenshot captures found to compare${NC}"
        exit 1
    fi
fi

DIR1="$SCREENSHOT_DIR/$COMMIT1"
DIR2="$SCREENSHOT_DIR/$COMMIT2"

# Verify directories exist
if [ ! -d "$DIR1" ]; then
    echo -e "${RED}Error: Directory not found: $DIR1${NC}"
    exit 1
fi

if [ ! -d "$DIR2" ]; then
    echo -e "${RED}Error: Directory not found: $DIR2${NC}"
    exit 1
fi

echo "Comparing:"
echo "  Base: $COMMIT1"
echo "  New:  $COMMIT2"
echo ""

# Create diff output directory
mkdir -p "$DIFF_OUTPUT_DIR"

# Results tracking
declare -a UNCHANGED_SCREENS
declare -a CHANGED_SCREENS
declare -a NEW_SCREENS
declare -a MISSING_SCREENS

# Compare each screenshot
compare_screenshots() {
    local base_dir="$1"
    local new_dir="$2"

    # Get all screenshots from both directories
    local all_files=$( (ls "$base_dir"/*.png 2>/dev/null | xargs -n1 basename; ls "$new_dir"/*.png 2>/dev/null | xargs -n1 basename) | sort -u )

    for file in $all_files; do
        local base_file="$base_dir/$file"
        local new_file="$new_dir/$file"
        local diff_file="$DIFF_OUTPUT_DIR/${file%.png}-diff.png"
        local screen_name="${file%.png}"

        # Check if file exists in both directories
        if [ ! -f "$base_file" ]; then
            NEW_SCREENS+=("$screen_name")
            echo -e "  ${GREEN}+ NEW:${NC} $screen_name"
            continue
        fi

        if [ ! -f "$new_file" ]; then
            MISSING_SCREENS+=("$screen_name")
            echo -e "  ${RED}- MISSING:${NC} $screen_name"
            continue
        fi

        # Compare files
        if $USE_IMAGEMAGICK; then
            # Get pixel difference percentage
            local diff_result=$(compare -metric AE "$base_file" "$new_file" "$diff_file" 2>&1 || true)
            local diff_pixels=$(echo "$diff_result" | grep -o '[0-9]*' | head -1 || echo "0")

            # Get image dimensions for percentage calculation
            local total_pixels=$(identify -format '%w*%h\n' "$base_file" | bc)

            if [ "$total_pixels" -gt 0 ] && [ -n "$diff_pixels" ]; then
                local diff_percent=$(echo "scale=4; $diff_pixels * 100 / $total_pixels" | bc)

                if (( $(echo "$diff_percent > $SIGNIFICANT_THRESHOLD" | bc -l) )); then
                    CHANGED_SCREENS+=("$screen_name:$diff_percent")
                    echo -e "  ${RED}! CHANGED:${NC} $screen_name (${diff_percent}% different)"
                elif (( $(echo "$diff_percent > $DIFF_THRESHOLD" | bc -l) )); then
                    CHANGED_SCREENS+=("$screen_name:$diff_percent")
                    echo -e "  ${YELLOW}~ changed:${NC} $screen_name (${diff_percent}% different)"
                else
                    UNCHANGED_SCREENS+=("$screen_name")
                    rm -f "$diff_file"  # Remove diff file for unchanged screenshots
                fi
            else
                # Fallback to file comparison
                if cmp -s "$base_file" "$new_file"; then
                    UNCHANGED_SCREENS+=("$screen_name")
                else
                    CHANGED_SCREENS+=("$screen_name:unknown")
                    echo -e "  ${YELLOW}~ changed:${NC} $screen_name"
                fi
            fi
        else
            # Simple file comparison without ImageMagick
            if cmp -s "$base_file" "$new_file"; then
                UNCHANGED_SCREENS+=("$screen_name")
            else
                CHANGED_SCREENS+=("$screen_name:unknown")
                echo -e "  ${YELLOW}~ changed:${NC} $screen_name"
            fi
        fi
    done
}

echo "Comparing screenshots..."
compare_screenshots "$DIR1" "$DIR2"

# Summary
echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo -e "  ${GREEN}Unchanged:${NC} ${#UNCHANGED_SCREENS[@]}"
echo -e "  ${YELLOW}Changed:${NC}   ${#CHANGED_SCREENS[@]}"
echo -e "  ${GREEN}New:${NC}       ${#NEW_SCREENS[@]}"
echo -e "  ${RED}Missing:${NC}   ${#MISSING_SCREENS[@]}"

# Generate HTML report if requested
if $GENERATE_HTML; then
    HTML_FILE="$DIFF_OUTPUT_DIR/report.html"

    cat > "$HTML_FILE" << 'HTMLHEAD'
<!DOCTYPE html>
<html>
<head>
    <title>Screenshot Diff Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 20px; background: #1a1a1a; color: #fff; }
        h1 { color: #fff; }
        .summary { display: flex; gap: 20px; margin-bottom: 30px; }
        .stat { padding: 15px 25px; border-radius: 8px; }
        .stat.unchanged { background: #1d4a1d; }
        .stat.changed { background: #4a4a1d; }
        .stat.new { background: #1d4a4a; }
        .stat.missing { background: #4a1d1d; }
        .screen { margin-bottom: 30px; padding: 20px; background: #2a2a2a; border-radius: 8px; }
        .screen h3 { margin-top: 0; }
        .images { display: flex; gap: 10px; flex-wrap: wrap; }
        .images img { max-width: 300px; border-radius: 4px; }
        .label { font-size: 12px; color: #888; margin-bottom: 5px; }
        .diff-highlight { border: 2px solid #ff6b6b; }
    </style>
</head>
<body>
    <h1>Screenshot Diff Report</h1>
HTMLHEAD

    echo "<p>Comparing <strong>$COMMIT1</strong> → <strong>$COMMIT2</strong></p>" >> "$HTML_FILE"

    echo '<div class="summary">' >> "$HTML_FILE"
    echo "<div class=\"stat unchanged\"><strong>${#UNCHANGED_SCREENS[@]}</strong> Unchanged</div>" >> "$HTML_FILE"
    echo "<div class=\"stat changed\"><strong>${#CHANGED_SCREENS[@]}</strong> Changed</div>" >> "$HTML_FILE"
    echo "<div class=\"stat new\"><strong>${#NEW_SCREENS[@]}</strong> New</div>" >> "$HTML_FILE"
    echo "<div class=\"stat missing\"><strong>${#MISSING_SCREENS[@]}</strong> Missing</div>" >> "$HTML_FILE"
    echo '</div>' >> "$HTML_FILE"

    # Show changed screens
    if [ ${#CHANGED_SCREENS[@]} -gt 0 ]; then
        echo '<h2>Changed Screens</h2>' >> "$HTML_FILE"
        for entry in "${CHANGED_SCREENS[@]}"; do
            screen="${entry%%:*}"
            percent="${entry#*:}"
            echo "<div class=\"screen\">" >> "$HTML_FILE"
            echo "<h3>$screen ($percent% different)</h3>" >> "$HTML_FILE"
            echo '<div class="images">' >> "$HTML_FILE"
            echo "<div><div class=\"label\">Before ($COMMIT1)</div><img src=\"../$COMMIT1/${screen}.png\"></div>" >> "$HTML_FILE"
            echo "<div><div class=\"label\">After ($COMMIT2)</div><img src=\"../$COMMIT2/${screen}.png\"></div>" >> "$HTML_FILE"
            if [ -f "$DIFF_OUTPUT_DIR/${screen}-diff.png" ]; then
                echo "<div><div class=\"label\">Diff</div><img src=\"${screen}-diff.png\" class=\"diff-highlight\"></div>" >> "$HTML_FILE"
            fi
            echo '</div></div>' >> "$HTML_FILE"
        done
    fi

    # Show new screens
    if [ ${#NEW_SCREENS[@]} -gt 0 ]; then
        echo '<h2>New Screens</h2>' >> "$HTML_FILE"
        for screen in "${NEW_SCREENS[@]}"; do
            echo "<div class=\"screen\">" >> "$HTML_FILE"
            echo "<h3>$screen</h3>" >> "$HTML_FILE"
            echo '<div class="images">' >> "$HTML_FILE"
            echo "<div><div class=\"label\">New ($COMMIT2)</div><img src=\"../$COMMIT2/${screen}.png\"></div>" >> "$HTML_FILE"
            echo '</div></div>' >> "$HTML_FILE"
        done
    fi

    echo '</body></html>' >> "$HTML_FILE"

    echo ""
    echo -e "${GREEN}HTML report generated:${NC} $HTML_FILE"
    echo "Open with: open \"$HTML_FILE\""
fi

# List changed files
if [ ${#CHANGED_SCREENS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Changed screens:${NC}"
    for entry in "${CHANGED_SCREENS[@]}"; do
        screen="${entry%%:*}"
        echo "  - $screen"
    done
fi

echo ""
echo -e "${CYAN}Diff images saved to:${NC} $DIFF_OUTPUT_DIR"
