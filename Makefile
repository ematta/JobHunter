# JobHunter Makefile

# Variables
APP_NAME = JobHunter
APP_DIR = $(APP_NAME).app
CONTENTS_DIR = $(APP_DIR)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources
BUILD_DIR = .build/debug

# Default target
.PHONY: all
all: build app

# Check if Swift is installed
.PHONY: check-swift
check-swift:
	@command -v swift >/dev/null 2>&1 || { echo "Swift is not installed. Please install Swift for macOS."; exit 1; }

# Build the Swift project
.PHONY: build
build: check-swift
	@echo "Building $(APP_NAME)..."
	@swift build || { echo "Build failed."; exit 1; }
	@echo "Build successful!"

# Run tests
.PHONY: test
test: check-swift
	@echo "Running tests..."
	@swift test || { echo "Tests failed."; exit 1; }
	@echo "All tests passed!"

# Create the app bundle
.PHONY: app
app: build
	@echo "Creating app bundle: $(APP_DIR)"
	@rm -rf $(APP_DIR)
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@cp $(BUILD_DIR)/$(APP_NAME) $(MACOS_DIR)/
	@cp Info.plist $(CONTENTS_DIR)/
	@echo "Created app bundle: $(APP_DIR)"

# Run the application
.PHONY: run
run: app
	@echo "Running $(APP_NAME)..."
	@open $(APP_DIR)

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning up..."
	@rm -rf $(APP_DIR)
	@swift package clean
	@echo "Clean completed."

# Help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all    - Build the project and create the app bundle (default)"
	@echo "  build  - Build the Swift project"
	@echo "  test   - Run all tests"
	@echo "  app    - Create the app bundle"
	@echo "  run    - Create the app bundle and run the application"
	@echo "  clean  - Remove all build artifacts"
	@echo "  help   - Display this help message" 