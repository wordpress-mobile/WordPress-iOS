GUTENBERG_VERSION := v1.121.0
FRAMEWORKS_DIR := WordPress/Frameworks

.PHONY: dependencies

dependencies:
	./Scripts/download-gutenberg-xcframeworks.sh $(GUTENBERG_VERSION) $(FRAMEWORKS_DIR)
