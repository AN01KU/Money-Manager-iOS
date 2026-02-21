PROJECT = Money Manager.xcodeproj
SCHEME = Money Manager
DESTINATION = platform=iOS Simulator,name=iPhone 17
SIGNING = CODE_SIGNING_ALLOWED=NO

.PHONY: build test test-unit test-ui clean

build:
	xcodebuild build \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		$(SIGNING)

test: test-unit

test-unit:
	xcodebuild test \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		-only-testing:"Money ManagerTests" \
		$(SIGNING)

test-ui:
	xcodebuild test \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination "$(DESTINATION)" \
		-only-testing:"Money ManagerUITests" \
		$(SIGNING)

clean:
	xcodebuild clean \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)"
	rm -rf ~/Library/Developer/Xcode/DerivedData
