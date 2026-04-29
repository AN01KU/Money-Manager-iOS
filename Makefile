PROJECT = Money Manager.xcodeproj
SCHEME = Money Manager
SIMULATOR_ID := $(shell xcrun simctl list devices available | grep -E "iPhone [0-9]+" | tail -1 | awk -F '[()]' '{print $$2}')
DESTINATION = platform=iOS Simulator,id=$(SIMULATOR_ID)
SIGNING = CODE_SIGNING_ALLOWED=NO
COVERAGE = -enableCodeCoverage YES
TEST_RESULTS = ./test_results.xcresult

XCODEBUILD_TEST = xcodebuild test \
	-project "$(PROJECT)" \
	-scheme "$(SCHEME)" \
	-destination "$(DESTINATION)" \
	$(SIGNING) \
	$(COVERAGE) \
	-resultBundlePath "$(TEST_RESULTS)"

BUILD_DIR := $(shell xcodebuild build \
	-project "$(PROJECT)" \
	-scheme "$(SCHEME)" \
	-destination "$(DESTINATION)" \
	$(SIGNING) \
	-showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | awk '{print $$3}')
APP_PATH = $(BUILD_DIR)/Money Manager.app
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")

.PHONY: build test test-unit test-ui test-api test-one coverage clean screenshots screenshot-one _export-screenshots

build:
	xcodebuild build \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		$(SIGNING)

test:
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -skip-testing:"Money ManagerUITests/ScreenshotGenerator"

test-unit:
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerTests" -skip-testing:"Money ManagerTests/APIIntegrationTests"

test-ui:
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerUITests" -skip-testing:"Money ManagerUITests/ScreenshotGenerator"

test-api:
	@echo "Running API integration tests sequentially"
	@echo ""
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerTests/APIIntegrationTests" -parallel-testing-enabled NO

test-one:
	@echo "Usage: make test-one TEST=BackupViewModelTests"
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerTests/$(TEST)"

coverage:
	xcrun xccov view --report $(TEST_RESULTS) 2>/dev/null | head -10

# ── Screenshots ───────────────────────────────────────────────────────────────
# Captures all app screens using a real test account (requires backend reachable).
# After the run, copies PNGs from the simulator's Documents dir to Screenshots/.
#
#   make screenshots              → capture all screens
#   make screenshot-one TAG=overview  → capture a single screen

screenshots:
	@echo "▶ Running screenshot tests (serial, no clones)..."
	rm -rf $(TEST_RESULTS)
	xcodebuild test \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		$(SIGNING) \
		-only-testing:"Money ManagerUITests/ScreenshotGenerator/testGenerateAllScreenshots" \
		-parallel-testing-enabled NO \
		-resultBundlePath "$(TEST_RESULTS)" 2>&1 | tee /tmp/xcodebuild-screenshots.log | tail -5; \
	STATUS=$${PIPESTATUS[0]}; \
	$(MAKE) _export-screenshots TEST_PASSED=$$STATUS

screenshot-one:
	@echo "▶ Capturing screenshot for tag: $(TAG)"
	rm -rf $(TEST_RESULTS)
	xcodebuild test \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		$(SIGNING) \
		-only-testing:"Money ManagerUITests/ScreenshotGenerator/testCaptureSingleScreen" \
		-parallel-testing-enabled NO \
		-resultBundlePath "$(TEST_RESULTS)" \
		TEST_RUNNER_SCREENSHOT_TAG=$(TAG) 2>&1 | tee /tmp/xcodebuild-screenshots.log | tail -5; \
	STATUS=$${PIPESTATUS[0]}; \
	$(MAKE) _export-screenshots TEST_PASSED=$$STATUS

TEST_PASSED ?= 1

_export-screenshots:
	@echo "▶ Exporting screenshots from test result bundle..."
	@TMP=$$(mktemp -d); \
	xcrun xcresulttool export attachments \
		--path "$(TEST_RESULTS)" \
		--output-path "$$TMP" 2>/dev/null; \
	python3 scripts/export_screenshots.py "$$TMP" "Screenshots"; \
	rm -rf "$$TMP"; \
	if [ "$(TEST_PASSED)" = "0" ]; then \
		rm -rf "$(TEST_RESULTS)"; \
	else \
		echo "⚠ Tests failed — test results kept at $(TEST_RESULTS) for debugging"; \
	fi

release:
	xcodebuild build \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		-configuration Release \
		$(SIGNING)
	@APP=$$(xcodebuild build \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		-configuration Release \
		$(SIGNING) \
		-showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | awk '{print $$3}'); \
	echo "Zipping $$APP/Money Manager.app ..."; \
	cd "$$APP" && zip -r "$(CURDIR)/MoneyManager-$(VERSION)-Simulator.zip" "Money Manager.app"; \
	echo "Created: $(CURDIR)/MoneyManager-$(VERSION)-Simulator.zip"

clean:
	xcodebuild clean \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)"
	rm -rf ~/Library/Developer/Xcode/DerivedData
	rm -rf $(TEST_RESULTS)
	rm -f MoneyManager-*-Simulator.zip
