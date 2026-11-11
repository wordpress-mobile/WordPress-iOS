.PHONY: help dependencies credentials lint lintfix build-wordpress-for-testing build-jetpack-for-testing test-without-building junit-report

SHELL := /bin/bash

CI_SIMULATOR := iPhone 17 Pro
DERIVED_DATA := DerivedData
RESULTS_DIR := build/results

# `simctl` lists runtimes oldest first, so the last match is the newest.
find_simulator = xcrun simctl list devices available | grep -E '^ +$(CI_SIMULATOR) \(' | tail -1 | grep -oE '[0-9A-F-]{36}'

# Set in each recipe because the GNU Make 3.81 that ships with macOS ignores `.SHELLFLAGS`.
strict := set -euo pipefail

define build_for_testing
$(strict); \
udid="$$($(find_simulator))"; \
NSUnbufferedIO=YES xcodebuild \
	-workspace WordPress.xcworkspace \
	-scheme $(1) \
	-derivedDataPath $(DERIVED_DATA) \
	-destination "platform=iOS Simulator,id=$$udid" \
	build-for-testing \
	| xcbeautify
endef

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

build-wordpress-for-testing: ## Build WordPress for testing
	$(call build_for_testing,WordPress)

build-jetpack-for-testing: ## Build Jetpack for testing
	$(call build_for_testing,Jetpack)

# Workaround: on Xcode 27, post-test simulator diagnostics collection can hang until its 600 s timeout.
# Drop `-collect-test-diagnostics never` once a newer Xcode no longer does.
test-without-building: ## Run the WordPress unit tests from prebuilt products
	$(strict); \
	udid="$$($(find_simulator))"; \
	xctestrun="$$(ls $(DERIVED_DATA)/Build/Products/*WordPressUnitTests*.xctestrun | head -1)"; \
	xcrun simctl shutdown "$$udid" 2>/dev/null || true; \
	xcrun simctl erase "$$udid"; \
	rm -rf $(RESULTS_DIR)/WordPress.xcresult; \
	mkdir -p $(RESULTS_DIR); \
	NSUnbufferedIO=YES xcodebuild \
		-destination "platform=iOS Simulator,id=$$udid" \
		-derivedDataPath $(DERIVED_DATA) \
		-resultBundlePath $(RESULTS_DIR)/WordPress.xcresult \
		-xctestrun "$$xctestrun" \
		-collect-test-diagnostics never \
		test-without-building \
		| xcbeautify

junit-report: ## Convert the unit tests' result bundle to JUnit
	./Scripts/xcresult-to-junit.rb $(RESULTS_DIR)/WordPress.xcresult $(RESULTS_DIR)/report.junit
