.PHONY: help eval eval-quick eval-tags eval-summary open clean

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
	@echo "━━━ Utilities ━━━"
	@echo ""
	@echo "  make open              Open latest HTML report"
	@echo "  make clean             Clean all generated files"
	@echo "  make help              Show this help"
	@echo ""
	@echo "For evaluation CLI options: ./lib/evaluate.py --help"
	@echo ""

.DEFAULT_GOAL := help
