# Money Manager

A personal finance iOS app for tracking expenses, managing budgets, splitting costs with friends, and staying on top of your spending — all from your pocket.

> **Note:** This app is under active development. Features and UI are subject to change.

## Why Money Manager?

Most expense trackers are either too simple or bloated with features you don't need. Money Manager strikes the right balance — it handles your personal expenses, recurring bills, monthly budgets, **and** group expense splitting in one clean interface. No subscriptions, no ads, just your money, organized.

## Features

### 💰 Personal Expense Tracking
- Log expenses with amounts, categories, notes, and dates
- Quick-add with preset amounts for fast entry
- View and filter transactions by day or month
- Detailed transaction history with search

### 📊 Budget Management
- Set monthly budgets and track spending against them
- Visual breakdown of spending by category
- Dashboard with projected spending, daily averages, and remaining budget
- Over-budget alerts to keep you on track

### 🔁 Recurring Expenses
- Set up recurring expenses (daily, weekly, monthly)
- Flexible scheduling — choose specific days of the week or month
- Skip weekends or specific dates
- Auto-generates expenses so you never forget a bill

### 👥 Group Expense Splitting
- Create groups for trips, roommates, dinners, or any shared cost
- Add shared expenses and split them across group members
- Track balances — see who owes whom
- Record settlements to clear debts

### 🏷️ Custom Categories
- Comes with predefined spending categories
- Create your own categories with custom names, colors, and icons
- Organize expenses the way that makes sense to you

### 🌐 Sync & Offline Support
- Cloud sync via backend API — access your data across sessions
- Offline-first: log expenses without internet, sync when you're back online
- Pending sync indicator so you always know your data status

### ⚙️ Settings & Preferences
- Multi-currency support — pick your preferred currency
- Export data (coming soon — CSV/PDF)
- Authentication with secure keychain storage

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Architecture | MVVM |
| Local Persistence | SwiftData |
| Charts | Swift Charts |
| Networking | URLSession + async/await |
| Auth | Token-based (Keychain storage) |
| Sync | Custom offline-first sync service |

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/an01ku/money-manager-ios.git
   ```
2. Open `Money Manager.xcodeproj` in Xcode
3. Select a simulator or connected device
4. Build and run (⌘R)

### Build & Test via Makefile

```bash
make build       # Build the project
make test        # Run unit tests
make test-ui     # Run UI tests
make clean       # Clean build artifacts
```

## Project Structure

```
Money Manager/
├── Models/          # Data models (Expense, Budget, Category, Split, etc.)
├── ViewModels/      # MVVM view models for each screen
├── Pages/           # Full-screen views (Overview, Budgets, Groups, Auth, etc.)
├── Components/      # Reusable UI components (Budget/, Category/, Transaction/, Common/)
├── Services/        # API, Sync, Data, Keychain, and Error handling services
├── Helpers/         # App constants and utilities
├── ContentView.swift
└── Money_ManagerApp.swift
```

## License

This project is for personal use.
