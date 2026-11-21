.PHONY: help dependencies credentials lint lintfix sim-login

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-20s %s\n", $$1, $$2}'

dependencies: ## Download and cache Gutenberg XCFrameworks
	./Scripts/download-gutenberg-xcframeworks.sh

credentials: ## Set up your own WordPress.com API credentials (external contributors)
	./Scripts/setup-credentials.sh

lint: ## Lint Swift code with SwiftLint: the whole project, or PATHS="file1 file2"
	./Scripts/swiftlint.sh $(PATHS)

lintfix: ## Fix SwiftLint violations where possible: the whole project, or PATHS="file1 file2"
	./Scripts/swiftlint.sh --fix $(PATHS)

sim-login: ## Sign an iOS Simulator into WordPress.com (vars: DEVICE, APP, RESET=1; token from ~/.wpcom-token)
	./Scripts/sim-signin.sh $(if $(APP),--app $(APP)) $(if $(DEVICE),--device $(DEVICE)) $(if $(RESET),--reset) $(ARGS)
