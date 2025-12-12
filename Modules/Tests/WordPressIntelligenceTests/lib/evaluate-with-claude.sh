#!/bin/bash
set -euo pipefail

# Python-based Evaluation Pipeline
# This is a thin wrapper that runs xcodebuild and calls Python for evaluation
#
# Usage:
#   ./evaluate-with-claude-py.sh                           # Run all excerpt tests (default)
#   ./evaluate-with-claude-py.sh --test-type tags          # Run all tag tests
#   ./evaluate-with-claude-py.sh --skip-tests              # Only evaluate existing JSON
#   ./evaluate-with-claude-py.sh --simulator "iPhone 15"   # Use specific simulator
#   ./evaluate-with-claude-py.sh --only-testing "PostExcerptGeneratorTests/spanishHTMLContent()"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../../../.."
MODULES_DIR="${PROJECT_ROOT}/Modules"
OUTPUT_DIR="${TMPDIR}WordPressIntelligence-Tests"

# Create timestamped evaluation directory
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
EVAL_RUN_DIR="${OUTPUT_DIR}/evaluation-${TIMESTAMP}"

# Default parameters
SKIP_TESTS=false
SIMULATOR_NAME="iPhone 16 Pro"
ONLY_TESTING=""
TEST_TYPE="excerpts"
MODEL="sonnet"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --test-type)
            TEST_TYPE="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --simulator)
            SIMULATOR_NAME="$2"
            shift 2
            ;;
        --only-testing)
            ONLY_TESTING="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--test-type excerpts|tags|summary] [--model sonnet|opus|haiku] [--skip-tests] [--simulator \"SIMULATOR_NAME\"] [--only-testing \"TEST_IDENTIFIER\"]"
            exit 1
            ;;
    esac
done

# Colors
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check dependencies
echo "Checking dependencies..."

if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Error: python3 not found${NC}"
    exit 1
fi

if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}Error: claude CLI not found${NC}"
    echo "Install with: pip install claude-cli && claude configure"
    exit 1
fi

# Test type mapping (using case instead of associative arrays for compatibility)
case "$TEST_TYPE" in
    excerpts)
        TEST_TARGET_CLASS="PostExcerptGeneratorTests"
        TEST_ICON="🖥️"
        TEST_NAME="Excerpt Generation"
        ;;
    tags)
        TEST_TARGET_CLASS="TagSuggestionGeneratorTests"
        TEST_ICON="🏷️"
        TEST_NAME="Tag Suggestion"
        ;;
    summary)
        TEST_TARGET_CLASS="PostSummaryGeneratorTests"
        TEST_ICON="📝"
        TEST_NAME="Post Summary"
        ;;
    *)
        TEST_TARGET_CLASS="PostExcerptGeneratorTests"
        TEST_ICON="🔬"
        TEST_NAME="Unknown"
        ;;
esac

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${TEST_ICON}  ${TEST_NAME} Evaluation Pipeline (Python)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Test results:       ${OUTPUT_DIR}/test-results.xcresult"
echo "Evaluation results: ${EVAL_RUN_DIR}"
echo ""

# Step 1: Run Swift tests
if [ "$SKIP_TESTS" = false ]; then
    echo -e "${CYAN}Step 1: Running Swift ${TEST_NAME} tests...${NC}"
    echo ""

    # Create output directories
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$EVAL_RUN_DIR"

    # Run tests and capture xcresult bundle
    cd "$MODULES_DIR"
    XCRESULT_PATH="${OUTPUT_DIR}/test-results.xcresult"

    # Remove existing xcresult bundle if it exists
    if [ -d "$XCRESULT_PATH" ]; then
        rm -rf "$XCRESULT_PATH"
    fi

    echo "Running tests..."

    # Determine test target
    if [ -n "$ONLY_TESTING" ]; then
        TEST_TARGET="WordPressIntelligenceTests/${ONLY_TESTING}"
        echo "  Only testing: $TEST_TARGET"
    else
        TEST_TARGET="WordPressIntelligenceTests/${TEST_TARGET_CLASS}"
    fi

    # Run tests with NSUnbufferedIO for real-time output
    if NSUnbufferedIO=YES xcodebuild test \
        -scheme Modules-Package \
        -destination "platform=iOS Simulator,name=${SIMULATOR_NAME},OS=26.0" \
        -only-testing:"${TEST_TARGET}" \
        -resultBundlePath "$XCRESULT_PATH" \
        2>&1 | tee "${OUTPUT_DIR}/swift-test-output.txt"; then
        echo ""
        echo -e "${GREEN}✓ Tests passed${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠ Some tests failed - continuing with evaluation${NC}"
    fi

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
else
    echo -e "${YELLOW}Skipping test execution (using existing output)${NC}"
    echo ""
    mkdir -p "$EVAL_RUN_DIR"
    XCRESULT_PATH="${OUTPUT_DIR}/test-results.xcresult"
fi

# Step 2-4: Python handles extraction, evaluation, and JSON report generation
cd "$SCRIPT_DIR"

# Temporarily disable exit-on-error to capture Python exit code properly
set +e
python3 evaluate.py \
    --test-output "${OUTPUT_DIR}/swift-test-output.txt" \
    --output-dir "$EVAL_RUN_DIR" \
    --test-type "$TEST_TYPE" \
    --model "$MODEL"

PYTHON_EXIT_CODE=$?
set -e

# Generate HTML report with embedded data
if [ -f "$SCRIPT_DIR/evaluation-viewer.html" ] && [ -f "$EVAL_RUN_DIR/evaluation-results.json" ]; then
    python3 "$SCRIPT_DIR/inject-report-data.py" \
        "$SCRIPT_DIR/evaluation-viewer.html" \
        "$EVAL_RUN_DIR/evaluation-results.json" \
        "$EVAL_RUN_DIR/evaluation-report.html"
    if [ $? -eq 0 ]; then
        echo "  ✓ HTML report: $EVAL_RUN_DIR/evaluation-report.html"
        echo ""
        echo "  To compare with baselines:"
        echo "    1. Open evaluation-report.html in your browser"
        echo "    2. Check browser console for baseline folder location"
        echo "    3. Click 'Compare with baseline' or drag and drop a baseline JSON file"
        echo "    4. Baseline directories: $OUTPUT_DIR/evaluation-*/"
    else
        echo "  ✗ HTML report generation failed"
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Display console summary
if [ -f "$SCRIPT_DIR/console_reporter.py" ] && [ -f "$EVAL_RUN_DIR/evaluation-results.json" ]; then
    python3 "$SCRIPT_DIR/console_reporter.py" \
        "$EVAL_RUN_DIR/evaluation-results.json" \
        "$XCRESULT_PATH"
fi

echo ""

# Exit with Python's exit code
exit $PYTHON_EXIT_CODE
