PROJECT = Money Manager.xcodeproj
SCHEME = Money Manager
SIMULATOR_ID := $(shell xcrun simctl list devices available | grep -E "iPhone [0-9]+" | tail -1 | awk -F '[()]' '{print $$2}')
DESTINATION = platform=iOS Simulator,id=$(SIMULATOR_ID)
SIGNING = CODE_SIGNING_ALLOWED=NO
COVERAGE = -enableCodeCoverage YES

.PHONY: build test-unit test-ui clean

build:
	xcodebuild build \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		$(SIGNING)

#test: test-unit

#test-all: test-unit test-ui

test-unit:
	xcodebuild test \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		-only-testing:"Money ManagerTests" \
		$(SIGNING)

test-coverage:
	rm -rf $(TEST_RESULTS)
	xcodebuild test \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		-only-testing:"Money ManagerTests" \
		$(SIGNING) \
		$(COVERAGE) \
		-resultBundlePath "$(TEST_RESULTS)"

test-ui:
	xcodebuild test \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		-only-testing:"Money ManagerUITests" \
		$(SIGNING)

coverage:
	xcrun xccov view --report $(TEST_RESULTS) 2>/dev/null | head -10

clean:
	xcodebuild clean \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)"
	rm -rf ~/Library/Developer/Xcode/DerivedData
