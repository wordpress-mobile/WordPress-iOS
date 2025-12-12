#!/bin/bash
set -euo pipefail

# Quick HTML Report Regeneration
# For fast iteration on HTML viewer comparison features
#
# Usage:
#   ./quick-rebuild-report.sh                    # Use latest report, no baseline
#   ./quick-rebuild-report.sh --with-baseline    # Generate mock baseline and compare
#   ./quick-rebuild-report.sh --baseline path.json  # Use specific baseline
#   ./quick-rebuild-report.sh --improve          # Generate baseline showing improvements
#   ./quick-rebuild-report.sh --regress          # Generate baseline showing regressions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${TMPDIR}WordPressIntelligence-Tests"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default options
WITH_BASELINE=false
BASELINE_FILE=""
VARIATION="1.0"
BIAS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-baseline)
            WITH_BASELINE=true
            shift
            ;;
        --baseline)
            BASELINE_FILE="$2"
            WITH_BASELINE=true
            shift 2
            ;;
        --improve)
            BIAS="--improve"
            WITH_BASELINE=true
            shift
            ;;
        --regress)
            BIAS="--regress"
            WITH_BASELINE=true
            shift
            ;;
        --variation)
            VARIATION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--with-baseline] [--baseline FILE] [--improve] [--regress] [--variation VALUE]"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Quick HTML Report Rebuild${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Find latest evaluation directory
LATEST_EVAL=$(ls -td "${OUTPUT_DIR}"/evaluation-* 2>/dev/null | head -1)

if [ -z "$LATEST_EVAL" ]; then
    echo -e "${YELLOW}Error: No evaluation directories found in ${OUTPUT_DIR}${NC}"
    echo "Run an evaluation first: ./evaluate-with-claude.sh"
    exit 1
fi

EVAL_JSON="${LATEST_EVAL}/evaluation-results.json"
if [ ! -f "$EVAL_JSON" ]; then
    echo -e "${YELLOW}Error: No evaluation-results.json found in ${LATEST_EVAL}${NC}"
    exit 1
fi

echo -e "${CYAN}Source evaluation:${NC} ${LATEST_EVAL}"
echo ""

# Generate baseline if requested
BASELINE_ARG=""
if [ "$WITH_BASELINE" = true ]; then
    if [ -z "$BASELINE_FILE" ]; then
        # Generate mock baseline
        MOCK_BASELINE="${OUTPUT_DIR}/mock-baseline.json"
        echo -e "${CYAN}Generating mock baseline...${NC}"

        python3 "${SCRIPT_DIR}/generate-mock-baseline.py" \
            "$EVAL_JSON" \
            "$MOCK_BASELINE" \
            --variation "$VARIATION" \
            --seed 42 \
            $BIAS

        echo ""
        BASELINE_FILE="$MOCK_BASELINE"
    else
        echo -e "${CYAN}Using baseline:${NC} ${BASELINE_FILE}"
        echo ""
    fi

    BASELINE_ARG="--baseline ${BASELINE_FILE}"
fi

# Create output directory for quick rebuild
REBUILD_DIR="${OUTPUT_DIR}/quick-rebuild"
mkdir -p "$REBUILD_DIR"

OUTPUT_HTML="${REBUILD_DIR}/evaluation-report.html"

# Regenerate HTML
echo -e "${CYAN}Regenerating HTML report...${NC}"
python3 "${SCRIPT_DIR}/inject-report-data.py" \
    "${SCRIPT_DIR}/evaluation-viewer.html" \
    "$EVAL_JSON" \
    "$OUTPUT_HTML" \
    $BASELINE_ARG

echo ""
echo -e "${GREEN}✓ HTML report regenerated${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Open in browser:${NC}"
echo "  ${OUTPUT_HTML}"
echo ""
echo -e "${CYAN}Quick commands:${NC}"
echo "  open \"${OUTPUT_HTML}\"                  # macOS"
echo "  xdg-open \"${OUTPUT_HTML}\"              # Linux"
echo ""

# Auto-open on macOS if available
if command -v open &> /dev/null; then
    echo -e "${CYAN}Opening in browser...${NC}"
    open "$OUTPUT_HTML"
fi

echo -e "${YELLOW}Tip: Edit ${SCRIPT_DIR}/evaluation-viewer.html and re-run this script for instant preview${NC}"
echo ""
