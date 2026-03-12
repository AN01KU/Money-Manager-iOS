<!-- Money Manager iOS App -->

<div align="center">
  <img src="https://raw.githubusercontent.com/AN01KU/Money-Manager-iOS/feat/mvp/Money%20Manager/Assets.xcassets/AppIcon.appiconset/Icon-1024.png" width="150" alt="Money Manager App Icon">
  
  # Money Manager

  [![CI][ci-badge]][ci-url] · [![Coverage][coverage-badge]][coverage-url]

  ![iOS][ios-badge] · ![Swift][swift-badge] · ![Xcode][xcode-badge]
  
  [ci-badge]: https://github.com/an01ku/money-manager-ios/actions/workflows/ci.yml/badge.svg
  [ci-url]: https://github.com/an01ku/money-manager-ios/actions/workflows/ci.yml
  [coverage-badge]: https://codecov.io/gh/an01ku/money-manager-ios/branch/main/graph/badge.svg
  [coverage-url]: https://codecov.io/gh/an01ku/money-manager-ios
  [ios-badge]: https://img.shields.io/badge/iOS-17%2B-blue
  [swift-badge]: https://img.shields.io/badge/Swift-5.9-orange
  [xcode-badge]: https://img.shields.io/badge/Xcode-26%2B-purple

</div>

A personal finance iOS app for tracking expenses, managing budgets, and staying on top of your spending.

## Features

### Expense Tracking
- Log expenses with amounts, categories, notes, and dates
- Quick-add with preset amounts for fast entry
- View and filter transactions by day or month
- Detailed transaction history with search functionality

### Budget Management
- Set monthly budgets and track spending against them
- Visual breakdown of spending by category
- Dashboard with projected spending, daily averages, and remaining budget
- Over-budget alerts to keep you on track

### Recurring Expenses
- Set up recurring expenses (daily, weekly, monthly)
- Flexible scheduling—choose specific days of the week or month
- Skip weekends or specific dates
- Auto-generates expenses so you never forget a bill

### Categories
- Comes with predefined spending categories
- Create your own categories with custom names, colors, and icons
- Organize expenses the way that makes sense to you

### Additional Features
- Multi-currency support
- Export data to CSV/JSON formats
- All data stored locally on device

## Tech Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI |
| Architecture | MVVM |
| Local Storage | SwiftData |
| Charts | Swift Charts |

## Requirements

| Requirement | Version |
|-------------|---------|
| iOS | 17.0+ |
| Xcode | 26.0+ |
| Swift | 5.9+ |

## Architecture

```
Money Manager/
├── Models/           # Data models (Expense, Budget, Category, etc.)
├── ViewModels/       # Business logic and state management
├── Pages/            # Screen-level views
├── Components/       # Reusable UI components
├── Services/         # Keychain and core services
└── Helpers/         # Constants and utilities
```

## Getting Started

### Prerequisites

1. Install [Xcode](https://developer.apple.com/xcode/) 26.0 or later
2. An Apple Developer account (for running on device)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/an01ku/money-manager-ios.git
   cd money-manager-ios
   ```

2. Open the project in Xcode:
   ```bash
   open Money\ Manager.xcodeproj
   ```

3. Select a simulator or connected device

4. Build and run: `Cmd + R`

### Development Commands

```bash
# Build the project
make build

# Run unit tests
make test-unit

# Run UI tests
make test-ui

# View coverage report
make coverage

# Clean build artifacts
make clean
```

## Testing

The project includes comprehensive unit and UI tests:

- **Unit Tests**: Model validation, ViewModel logic, data transformations
- **UI Tests**: User flow verification, screen rendering tests

Run tests with:
```bash
make test-unit
```

View coverage reports at: [codecov.io/gh/an01ku/money-manager-ios](https://codecov.io/gh/an01ku/money-manager-ios)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is for personal use. All rights reserved.

---

<div align="center">

Built with SwiftUI

</div>
