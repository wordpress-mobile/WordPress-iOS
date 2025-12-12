# WordPressIntelligence

AI-powered content intelligence for WordPress using Apple Foundation Models.

## Features

- **Excerpt Generation** - Generate 3 excerpt variations in 8 languages with configurable length/style
- **Tag Suggestions** - AI-powered tag recommendations
- **Post Summaries** - Automatic content summarization

## Requirements

- iOS 26.0+
- Device with Apple Intelligence support

## Usage

```swift
let generator = ExcerptGeneration(length: .medium, style: .engaging)
let excerpts = try await generator.generate(for: postContent)
```

**Languages**: English, Spanish, French, German, Italian, Portuguese, Japanese, Chinese
**Lengths**: Short (15-35 words), Medium (40-80 words), Long (90-130 words)
**Styles**: Engaging, Professional, Conversational, Formal, Witty

## Testing

### Standard XCTest

Run standard tests that verify language, length, and diversity:

```bash
cd Modules
xcodebuild test \
  -scheme Modules-Package \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0' \
  -only-testing:WordPressIntelligenceTests
```

### Quality Evaluation

Evaluate AI-generated content quality using Claude scoring. Requires [Claude CLI](https://github.com/anthropics/claude-cli).

**Location**: `Modules/Tests/WordPressIntelligenceTests/`

```bash
# Quick start
cd Modules/Tests/WordPressIntelligenceTests
make                    # Show all available commands
make eval               # Run full evaluation (all test types)
make eval-quick         # Run English excerpt evaluation
make eval TESTS="excerpts"       # Run only excerpt tests
make eval TESTS="excerpts tags"  # Run excerpt and tag tests
make eval-tags          # Evaluate tag suggestions
make eval-summary       # Evaluate post summaries
make open               # Open latest HTML report
```

**Common targets**:
- `make eval` - Run full evaluation for all test types (excerpts, tags, summary)
- `make eval TESTS="excerpts"` - Run only specific test types
- `make eval-quick` - Fast evaluation (English excerpts only)
- `make rebuild-improve` - Regenerate HTML with mock improvements (for UI development)
- `make open` - Open latest evaluation report
- `make help` - Show all available commands

For advanced options and HTML report development, see:
- `Modules/Tests/WordPressIntelligenceTests/Makefile`
- `Modules/Tests/WordPressIntelligenceTests/lib/DEVELOPMENT.md`

### Evaluation Output

Results are saved to `/tmp/WordPressIntelligence-Tests/evaluation-<timestamp>/`:

- **`evaluation-report.html`** - Interactive report with filtering, sorting, baseline comparison
- **`evaluation-results.json`** - Machine-readable data for CI/CD
- Console output with quick summary

**HTML Report Features**:
- Sortable columns (test name, status, score, duration)
- Filter by language, status, or comparison results
- Baseline comparison with delta indicators (↑ improved, ↓ regressed, = unchanged)
- Click any test to see detailed scores, generated content, and Claude feedback
- Score distribution dots (●●●) show pass/warn/fail for each excerpt

### Scoring

Quality scores use weighted criteria (1-10 scale):

**Excerpt Generation**:
- Language Match (3.0×), Grammar (2.0×), Relevance (2.0×) - critical factors
- Hook Quality (1.5×), Key Info (1.5×), Length, Style, Standalone, Engagement (1.0× each)
- Diversity: structural, angle, length, lexical variation

**Pass criteria**: Overall ≥ 7.0 AND no critical failures
**Needs Improvement**: 6.0-6.9 OR any score < 4.0
**Failed**: Language < 8.0 OR Grammar < 6.0 OR Overall < 6.0

*Note: Tag and summary evaluations use different criteria optimized for their use cases.*

## Extending Tests

### Adding Test Cases

1. Add test data to `lib/config.py`:
```python
"new_test_case": TestConfig(
    original_content="...",
    language="english",
    # ... other parameters
)
```

2. Update `Makefile` if adding new test type:
```makefile
eval-newtype:
    @./lib/evaluate-with-claude.sh --test-type newtype
```

### Customizing Evaluation Criteria

Edit scoring logic in `lib/evaluators.py`. Each test type has its own evaluator class with weighted criteria and thresholds.

### Developing HTML Report

For fast iteration on HTML report UI without re-running tests:

```bash
make rebuild-improve    # Regenerate with mock improvements
# Edit lib/evaluation-viewer.html
make rebuild-improve    # Instant preview
```

See `lib/DEVELOPMENT.md` for complete HTML development workflow.

## Troubleshooting

**Tests skipped**: Missing iOS 26 or Apple Intelligence support
**Language issues**: Check prompt in `Sources/WordPressIntelligence/ExcerptGeneration.swift`
**Evaluation fails**: Install/configure Claude CLI: `pip install claude-cli && claude configure`

See `CLAUDE.md` for project development guidelines.
