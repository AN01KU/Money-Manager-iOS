<!-- Money Manager iOS App -->
<p align="center">
  <img src="Money%20Manager/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="150" alt="Money Manager App Icon">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17%2B-blue.svg" alt="iOS Version">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift Version">
  <img src="https://img.shields.io/badge/Xcode-15%2B-purple.svg" alt="Xcode Version">
  <a href="https://github.com/an01ku/money-manager-ios/actions"><img src="https://github.com/an01ku/money-manager-ios/actions/workflows/tests.yml/badge.svg" alt="Tests"></a>
</p>

# Money Manager

A personal finance iOS app for tracking expenses, managing budgets, splitting costs with friends, and staying on top of your spending.

## About

Most expense trackers are either too simple or bloated with features you don't need. Money Manager strikes the right balance—it handles your personal expenses, recurring bills, monthly budgets, and group expense splitting in one clean interface. No subscriptions, no ads, just your money, organized.

> **Note:** This app is under active development. Features and UI are subject to change.

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

### Group Expense Splitting
- Create groups for trips, roommates, dinners, or any shared cost
- Add shared expenses and split them across group members
- Track balances—see who owes whom
- Record settlements to clear debts

### Categories
- Comes with predefined spending categories
- Create your own categories with custom names, colors, and icons
- Organize expenses the way that makes sense to you

### Additional Features
- Multi-currency support
- Export data to CSV/JSON formats
- All data stored locally on device

## Architecture

The app follows the **MVVM (Model-View-ViewModel)** architecture pattern with SwiftUI:

```
Money Manager/
├── Models/           # Data models (Expense, Budget, Category, etc.)
├── ViewModels/       # Business logic and state management
├── Views/            # SwiftUI views
├── Pages/            # Screen-level views
├── Components/       # Reusable UI components
├── Services/         # Keychain, and core services
└── Helpers/          # Constants and utilities
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI |
| Architecture | MVVM |
| Local Storage | SwiftData |
| Charts | Swift Charts |

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

### Prerequisites

1. Install [Xcode](https://developer.apple.com/xcode/) 15.0 or later
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

Current coverage: ~77%

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is for personal use. All rights reserved.

## Contact

- GitHub: [@an01ku](https://github.com/an01ku)
- Twitter: [@ankush_ganesh](https://twitter.com/ankush_ganesh)

---

<p align="center">Built with SwiftUI</p>
