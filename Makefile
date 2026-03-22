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
	$(XCODEBUILD_TEST)
	
test-unit:
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerTests"
	
test-ui:
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerUITests"
	
test-api:
	@echo "Running API integration tests sequentially (backend must be running at localhost:8080)"
	@echo ""
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerTests/APIIntegrationTests" -parallel-testing-enabled NO
	
test-one:
	@echo "Usage: make test-one TEST=BackupViewModelTests"
	rm -rf $(TEST_RESULTS)
	$(XCODEBUILD_TEST) -only-testing:"Money ManagerTests/$(TEST)"

coverage:
	xcrun xccov view --report $(TEST_RESULTS) 2>/dev/null | head -10

clean:
	xcodebuild clean \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)"
	rm -rf ~/Library/Developer/Xcode/DerivedData
	rm -rf $(TEST_RESULTS)
