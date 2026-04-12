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

.PHONY: build test test-unit test-ui coverage clean release

build:
	xcodebuild build \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		$(SIGNING)

test:
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST)
	
test-unit:
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerTests"
	
test-ui:
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerUITests"
	
test-one:
	@echo "Usage: make test-one TEST=BackupViewModelTests"
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerTests/$(TEST)"

coverage:
	xcrun xccov view --report $(TEST_RESULTS) 2>/dev/null | head -10

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
