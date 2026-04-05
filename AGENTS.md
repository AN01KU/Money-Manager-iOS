# AGENTS.md

## Project Overview

**Money Manager** — a personal finance iOS app built with SwiftUI (iOS 18.0+, Swift 6.0, MVVM, SwiftData).

For full project architecture, data models, directory structure, ViewModels, shared components, and key file references, load the project overview skill:

→ **`.agents/skills/project-overview/SKILL.md`**

---

## Build & Test Commands

Always use the Makefile. Do **not** run `xcodebuild` directly.

```bash
make build                          # Build the project
make test-unit                      # Run all unit tests
make test-one TEST=SomeTestClass    # Run a single test suite (use this when working on specific tests)
make test-ui                        # Run UI tests (slow — don't run automatically)
make test                           # Run everything
make coverage                       # View coverage summary
make clean                          # Clean build artifacts
```

When fixing or adding tests, always use `make test-one TEST=<TestClass>` to run only what you touched.

### Screenshots

Screenshots in `Screenshots/` are generated from the live test account via `ScreenshotGenerator`.

```bash
make screenshots                    # Capture all screens → copies PNGs to Screenshots/
make screenshot-one TAG=overview    # Capture a single screen by tag
```

**Run `make screenshots` before committing any UI change** so the screenshots stay current.

The generator lives in `Money ManagerUITests/Screenshots/ScreenshotGenerator.swift`.
Tags are defined in `Money ManagerUITests/Screenshots/ScreenshotTag.swift`.

To add a new screen:
1. Add a `case` to `ScreenshotTag`
2. Add a `captureXxx()` method in `ScreenshotGenerator` and call it from `captureAll()`

Requires the backend to be reachable and the test account (`ankush@gmail.com`) to exist.

### Test Output Handling

**IMPORTANT**: Never use `head`, `grep`, or `tail` to filter test output. The test result file is located at:
- `./test_results.xcresult`

To parse test results, **always use the `--legacy` flag** (required — without it xcresulttool errors):

```bash
xcrun xcresulttool get object --legacy --path ./test_results.xcresult --format json
```

To extract failure messages with file locations:

```bash
xcrun xcresulttool get object --legacy --path ./test_results.xcresult --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)

def find_issues(obj, depth=0):
    if depth > 20: return
    if isinstance(obj, dict):
        type_name = obj.get('_type', {}).get('_name', '')
        if 'Issue' in type_name or 'Failure' in type_name:
            msg = obj.get('message', {}).get('_value', '')
            if msg:
                loc = obj.get('documentLocationInCreatingWorkspace', {})
                url = loc.get('url', {}).get('_value', '')
                print(f'{url}: {msg}')
        for v in obj.values():
            find_issues(v, depth+1)
    elif isinstance(obj, list):
        for item in obj:
            find_issues(item, depth+1)

find_issues(data)
"
```

---

## Git Guidelines

### Commits

- Write short, imperative commit messages: `fix: budget calculation for leap year months`
- use prefixes like `feat:`, `fix:`, `chore:` — keep it plain and descriptive
- **Never push without explicit consent**
- Only stage files related to the current task — never `git add -A` or `git add .`

### Branching

- `main`, `develop` is the stable branch
- Feature branches: `feat/<short-description>`
- Bug fixes: `fix/<short-description>`
- Always branch from `develop`

### CI/CD

- CI runs on push to `main` and on PRs (see `.github/workflows/ci.yml`)
- CI triggers only when source, test, or project files change
- Pipeline: Build → Test → Coverage Report → Badge Update
- All tests must pass before merging
- Coverage threshold is 50% (warning, not blocking)

---

## Coding Guidelines

### Keep It Simple

- Write code that reads like plain English. If someone needs to squint to understand a function, it's too complex.
- Avoid over-engineering. No abstractions for the sake of abstractions.
- No code duplication — if you see repeated logic, extract it. Check `Helpers/` and `Components/Common/` before writing new utilities.
- Use existing shared components: `AppColors`, `AppConstants`, `CurrencyFormatter`, `EmptyStateView`, etc.

### Swift

- Target iOS 18.0+, Swift 6.0.
- Use `@Observable` classes (not `ObservableObject`) for view models. Mark them `@MainActor`.
- Use modern Swift concurrency — no GCD (`DispatchQueue`).
- `@State` must be `private`.
- Prefer `foregroundStyle()` over `foregroundColor()`.
- Prefer `clipShape(.rect(cornerRadius:))` over `cornerRadius()`.
- Use `NavigationStack` with `navigationDestination(for:)`, not `NavigationView`.
- Use `Tab` API, not `tabItem()`.
- Use `Button` for taps, not `onTapGesture()` (unless you need tap count/location).
- No force unwraps or force `try` unless truly unrecoverable.
- No C-style string formatting — use Swift's `FormatStyle` APIs.
- Filter user text with `localizedStandardContains()`, not `contains()`.
- Break views into separate `View` structs, not computed properties.
- Prefer Dynamic Type over hardcoded font sizes.
- No third-party dependencies without asking first.
- Avoid UIKit unless specifically needed.

Good references:
- [What to fix in AI-generated Swift code](https://www.hackingwithswift.com/articles/281/what-to-fix-in-ai-generated-swift-code) — Paul Hudson
- [twostraws/SwiftAgents](https://github.com/twostraws/SwiftAgents) — Swift/SwiftUI agent guidelines

---

## Testing Guidelines

Tests are **mandatory** for all business logic, view models, and model behavior.

### What Makes a Good Test

- Tests should verify **behavior**, not implementation details.
- Cover meaningful scenarios: happy paths, edge cases, error states, boundary conditions.
- A test like "initializer sets property value" is a **bad test** — it tests nothing useful.
- Don't write pointless tests to inflate coverage numbers. Coverage percentage is irrelevant; behavior coverage is what matters.

### Approach

- Follow **BDD/TDD**: write tests first or alongside implementation.
- Test names should read as behavior: `testAddTransaction_withZeroAmount_doesNotSave()`
- One assertion per logical concept per test.
- Use `make test-one TEST=YourTestClass` to run only the tests you're working on.

### What to Test

- ViewModel logic (calculations, state transitions, validation)
- Model behavior (computed properties, business rules)
- Edge cases (empty data, boundary values, date edge cases like month-end)
- Error handling paths

### What NOT to Test

- SwiftUI view layout (that's what UI tests and eyes are for)
- Simple property getters/setters
- Apple framework internals

---

## Code Review Checklist

Before submitting changes, verify:

- [ ] No duplicated logic — check existing helpers and components
- [ ] Tests cover the actual behavior being changed
- [ ] `make test-one TEST=<relevant>` passes
- [ ] No force unwraps introduced
- [ ] Uses existing shared utilities (`AppColors`, `AppConstants`, `CurrencyFormatter`)
- [ ] Code is straightforward — no cleverness for its own sake
- [ ] If a major flow changed, update `README.md` to reflect it
