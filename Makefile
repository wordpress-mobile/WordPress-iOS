.PHONY: help dependencies

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-20s %s\n", $$1, $$2}'

dependencies: ## Download and cache Gutenberg XCFrameworks
	./Scripts/download-gutenberg-xcframeworks.sh
