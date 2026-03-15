<!-- Money Manager iOS App -->

<p align="center">
  <img src="Money Manager/Assets.xcassets/AppIcon.appiconset/Icon-1024.png" width="120" alt="Money Manager" style="border-radius: 22%;">
</p>

<h1 align="center">Money Manager</h1>

<p align="center">
  A personal finance iOS app for tracking expenses, managing budgets, splitting costs with friends, and staying on top of your spending.
</p>

<p align="center">
  <a href="https://github.com/an01ku/money-manager-ios/actions/workflows/ci.yml">
    <img src="https://github.com/an01ku/money-manager-ios/actions/workflows/ci.yml/badge.svg" alt="CI">
  </a>
  <img src="https://img.shields.io/badge/iOS-18.0%2B-blue" alt="iOS 18.0+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/Xcode-16.4%2B-purple" alt="Xcode 16.4+">
</p>

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
- Flexible scheduling — choose specific days of the week or month
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
| iOS | 18.0+ |
| Xcode | 16.4+ |
| Swift | 6.0 |

## Architecture

```
Money Manager/
├── Models/           # Data models (Expense, Budget, Category, etc.)
├── ViewModels/       # Business logic and state management
├── Pages/            # Screen-level views
├── Components/       # Reusable UI components
├── Services/         # Keychain and core services
├── Helpers/          # Constants and utilities
├── ContentView.swift
└── Money_ManagerApp.swift
```

## Getting Started

### Prerequisites

1. Install [Xcode](https://developer.apple.com/xcode/) 16.4 or later
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

# Run a single test class
make test-one TEST=BackupViewModelTests

# View coverage report
make coverage

# Clean build artifacts
make clean
```

## Testing

The project includes comprehensive unit and UI tests:

- **Unit Tests** — Model validation, ViewModel logic, data transformations
- **UI Tests** — User flow verification, screen rendering tests

Run tests with:
```bash
make test-unit
```

View coverage locally with `make coverage`.

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

<p align="center">Built with ❤️ and SwiftUI</p>
