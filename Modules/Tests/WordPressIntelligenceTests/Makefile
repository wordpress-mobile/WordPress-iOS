.PHONY: help eval eval-quick eval-tags eval-summary rebuild rebuild-improve rebuild-regress rebuild-subtle rebuild-dramatic open clean

# =============================================================================
# Evaluation Targets - Run full evaluations with Claude scoring
# =============================================================================

# Default test types (all of them)
TESTS ?= excerpts tags summary

eval:
	@for test_type in $(TESTS); do \
		echo "Running evaluation for $$test_type..."; \
		./lib/evaluate.py --test-type $$test_type || exit 1; \
	done

eval-quick:
	@./lib/evaluate.py --only-testing "PostExcerptGeneratorTests/excerptGenerationEnglish(parameters:)"

eval-tags:
	@./lib/evaluate.py --test-type tags

eval-summary:
	@./lib/evaluate.py --test-type summary

# =============================================================================
# HTML Report Development - Fast iteration without re-running tests
# =============================================================================

rebuild:
	@./lib/quick-rebuild-report.sh

rebuild-improve:
	@./lib/quick-rebuild-report.sh --improve

rebuild-regress:
	@./lib/quick-rebuild-report.sh --regress

rebuild-subtle:
	@./lib/quick-rebuild-report.sh --improve --variation 0.3

rebuild-dramatic:
	@./lib/quick-rebuild-report.sh --regress --variation 2.0

# =============================================================================
# Utilities
# =============================================================================

open:
	@LATEST=$$(ls -t "$(TMPDIR)WordPressIntelligence-Tests/*/evaluation-report.html" 2>/dev/null | head -1); \
	if [ -n "$$LATEST" ]; then \
		echo "Opening: $$LATEST"; \
		open "$$LATEST"; \
	else \
		echo "No report found. Run 'make eval' or 'make rebuild' first."; \
	fi

clean:
	@echo "Cleaning generated files..."
	@rm -rf "$(TMPDIR)WordPressIntelligence-Tests"
	@echo "✓ Cleaned"

# =============================================================================
# Help
# =============================================================================

help:
	@echo "┌─────────────────────────────────────────────────────────┐"
	@echo "│  WordPressIntelligence Evaluation Test Suite           │"
	@echo "└─────────────────────────────────────────────────────────┘"
	@echo ""
	@echo "━━━ Evaluation (Run tests + Claude scoring) ━━━"
	@echo ""
	@echo "  make eval              Run all test types (excerpts, tags, summary)"
	@echo "  make eval TESTS=\"excerpts\"                Run only excerpt tests"
	@echo "  make eval TESTS=\"excerpts tags\"           Run excerpt and tag tests"
	@echo "  make eval-quick        Run English excerpt tests only"
	@echo "  make eval-tags         Run tag suggestion tests"
	@echo "  make eval-summary      Run post summary tests"
	@echo ""
	@echo "━━━ HTML Report Development (No test runs) ━━━"
	@echo ""
	@echo "  make rebuild           Rebuild report (no baseline)"
	@echo "  make rebuild-improve   Rebuild with mock improvements"
	@echo "  make rebuild-regress   Rebuild with mock regressions"
	@echo "  make rebuild-subtle    Rebuild with subtle changes (±0.3)"
	@echo "  make rebuild-dramatic  Rebuild with dramatic changes (±2.0)"
	@echo ""
	@echo "━━━ Utilities ━━━"
	@echo ""
	@echo "  make open              Open latest HTML report"
	@echo "  make clean             Clean all generated files"
	@echo "  make help              Show this help"
	@echo ""
	@echo "For HTML development workflow: lib/DEVELOPMENT.md"
	@echo "For evaluation CLI options: ./lib/evaluate.py --help"
	@echo ""

.DEFAULT_GOAL := help
