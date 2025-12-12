# Development Guide: HTML Reporter

Guide for iterating quickly on the HTML evaluation viewer.

## Quick Rebuild Workflow

For fast iteration on comparison features **without re-running evaluations**:

```bash
# Navigate to test directory
cd Modules/Tests/WordPressIntelligenceTests

# Rebuild HTML with different baseline scenarios
./lib/quick-rebuild-report.sh --improve     # Show improvements vs baseline
./lib/quick-rebuild-report.sh --regress     # Show regressions vs baseline
./lib/quick-rebuild-report.sh               # No baseline comparison
```

### How It Works

1. **Uses latest evaluation data** from `/tmp/WordPressIntelligence-Tests/`
2. **Generates mock baseline** by perturbing scores
3. **Rebuilds HTML** with comparison enabled
4. **Auto-opens** in your browser

**Result**: Instant preview of your HTML changes with realistic comparison data.

---

## Iteration Loop

The fastest way to develop comparison features:

```bash
# 1. Edit the HTML template
vim lib/evaluation-viewer.html

# 2. Rebuild and preview (takes ~1 second)
./lib/quick-rebuild-report.sh --improve

# 3. Browser auto-refreshes, review changes
# 4. Repeat!
```

This is **100x faster** than re-running the full evaluation pipeline.

---

## Mock Baseline Generator

### Basic Usage

```bash
# Generate mock baseline with random variations
python3 lib/generate-mock-baseline.py \
    input.json \
    baseline.json
```

### Advanced Options

```bash
# Show improvement (current better than baseline)
python3 lib/generate-mock-baseline.py \
    input.json baseline.json --improve --variation 1.5

# Show regression (current worse than baseline)
python3 lib/generate-mock-baseline.py \
    input.json baseline.json --regress --variation 0.8

# Control time delta
python3 lib/generate-mock-baseline.py \
    input.json baseline.json --hours-ago 48

# Reproducible results with seed
python3 lib/generate-mock-baseline.py \
    input.json baseline.json --seed 42
```

### Parameters

| Flag | Description | Default |
|------|-------------|---------|
| `--variation` | Score variation range (±) | `0.5` |
| `--hours-ago` | Baseline timestamp offset | `24` |
| `--seed` | Random seed for reproducibility | Random |
| `--improve` | Bias: current > baseline | No bias |
| `--regress` | Bias: current < baseline | No bias |

---

## Testing Scenarios

### 1. Mixed Results (Most Realistic)

```bash
./lib/quick-rebuild-report.sh --with-baseline
# Shows random mix of improvements, regressions, and unchanged tests
```

### 2. All Improvements

```bash
./lib/quick-rebuild-report.sh --improve --variation 1.0
# Perfect for testing green indicators, upward arrows, positive deltas
```

### 3. All Regressions

```bash
./lib/quick-rebuild-report.sh --regress --variation 1.0
# Test red indicators, downward arrows, negative deltas
```

### 4. Subtle Changes

```bash
./lib/quick-rebuild-report.sh --improve --variation 0.2
# Small deltas to test threshold detection
```

### 5. Dramatic Changes

```bash
./lib/quick-rebuild-report.sh --regress --variation 2.0
# Large deltas to test extreme cases
```

### 6. Using Real Baseline

```bash
# Compare two actual evaluation runs
./lib/quick-rebuild-report.sh \
    --baseline /tmp/WordPressIntelligence-Tests/evaluation-2025-12-11-143513/evaluation-results.json
```

---

## Development Tips

### Live Editing

1. Keep the HTML file open in your editor
2. Keep the browser window visible
3. Run `./lib/quick-rebuild-report.sh --improve` after each edit
4. Browser will load the updated report instantly

### Browser DevTools

The HTML uses modular JavaScript architecture:

- **AppState**: Manages data and state
- **Renderer**: Generates HTML from data
- **TableController**: Handles sorting/filtering
- **BaselineManager**: Loads baseline data
- **ComparisonEngine**: Calculates deltas

Inspect `window` in console to debug:
```javascript
// In browser console
AppState.currentReport      // Current evaluation data
AppState.currentBaseline    // Baseline data (if loaded)
AppState.filters            // Active filters
TableController.allRows     // All table rows
```

### Testing Comparison Features

Key areas to test:

1. **Delta Column**: Shows score difference vs baseline
2. **Baseline Rows**: Rendered below current rows
3. **Comparison Filter**: Filter by improved/degraded/unchanged
4. **Drag & Drop**: Drop JSON files to load baseline
5. **Visual Indicators**: Colors for improvement/regression
6. **Info Panel**: Comparison metadata display

### CSS Variables

Theme colors defined in `:root`:
```css
--color-excellent: #218838
--color-good: #28a745
--color-warning: #fd7e14
--color-poor: #dc3545
```

Supports dark mode via `@media (prefers-color-scheme: dark)`.

---

## File Structure

```
lib/
├── evaluation-viewer.html       # Main HTML template
├── inject-report-data.py        # Embeds JSON into HTML
├── generate-mock-baseline.py    # Creates test baselines
├── quick-rebuild-report.sh      # Fast rebuild script
├── evaluate.py                  # Main evaluation orchestrator
├── evaluators.py                # Scoring logic
├── config.py                    # Test type configs
└── DEVELOPMENT.md               # This file
```

---

## Common Issues

### "No evaluation directories found"

Run an evaluation first:
```bash
./evaluate-with-claude.sh --only-testing "PostExcerptGeneratorTests/excerptGenerationEnglish(parameters:)"
```

### HTML not updating

Clear browser cache or use hard refresh (Cmd+Shift+R on macOS).

### Baseline comparison not working

Check that both JSONs have matching test names:
```bash
# Compare test names
jq '.results[].testName' current.json
jq '.results[].testName' baseline.json
```

---

## Next Steps

After validating changes with mock data:

1. Run full evaluation to get real data
2. Compare actual runs to verify behavior
3. Test with different test types (excerpts, tags, summaries)

---

## Full Pipeline (When Needed)

Only run the full pipeline when you need fresh evaluation data:

```bash
# Full evaluation with Claude scoring (~30-60 seconds)
./evaluate-with-claude.sh

# With baseline comparison
./evaluate-with-claude.sh
# Then manually load baseline in HTML viewer
```
