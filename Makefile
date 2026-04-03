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
	@echo "Running API integration tests sequentially (backend must running, `curl https://{BASE_URL}/health`) "
	@echo ""
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerTests/APIIntegrationTests" -parallel-testing-enabled NO
	
test-one:
	@echo "Usage: make test-one TEST=BackupViewModelTests"
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerTests/$(TEST)"

coverage:
	xcrun xccov view --report $(TEST_RESULTS) 2>/dev/null | head -10

.PHONY: build test test-unit test-ui test-api test-one coverage clean screenshots screenshot-one _export-screenshots

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
		-resultBundlePath "$(TEST_RESULTS)" 2>&1 | tail -5 || true
	@$(MAKE) _export-screenshots

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
		TEST_RUNNER_SCREENSHOT_TAG=$(TAG) 2>&1 | tail -5 || true
	@$(MAKE) _export-screenshots

_export-screenshots:
	@echo "▶ Exporting screenshots from test result bundle..."
	@TMP=$$(mktemp -d); \
	xcrun xcresulttool export attachments \
		--path "$(TEST_RESULTS)" \
		--output-path "$$TMP" 2>/dev/null; \
	if python3 scripts/export_screenshots.py "$$TMP" "Screenshots"; then \
		rm -rf "$(TEST_RESULTS)"; \
	else \
		echo "⚠ Export failed — test results kept at $(TEST_RESULTS)"; \
	fi; \
	rm -rf "$$TMP"

clean:
	xcodebuild clean \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)"
	rm -rf ~/Library/Developer/Xcode/DerivedData
	rm -rf $(TEST_RESULTS)
