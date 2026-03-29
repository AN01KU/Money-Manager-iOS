---
name: money-manager-overview
description: Get comprehensive insights into the money-manager-ios project - a personal finance iOS app built with SwiftUI. Use this skill to understand project architecture, data models, ViewModels, directory structure, and development patterns. This skill helps AI agents navigate the codebase and find relevant files for specific tasks.
---

# Project Overview Skill

## Overview

This skill provides comprehensive insights into the **money-manager-ios** project - a personal finance iOS app built with SwiftUI. Use this skill to understand the project architecture, patterns, data models, and development conventions. This skill is designed for AI agents working on this codebase.

## When to Use

- Onboarding to the project codebase
- Understanding the architecture and patterns
- Finding specific files or components
- Writing tests or new features
- Understanding data flow and state management

---

## Project Summary

**Money Manager** is a personal finance iOS app for:
- Tracking income and expenses with categories, descriptions, and timestamps
- Managing monthly budgets with real-time progress
- Setting up recurring transactions (daily, weekly, monthly)
- Creating custom categories with colors and icons
- Multi-currency support with CSV/JSON export

### Key Metrics
| Metric | Value |
|--------|-------|
| iOS Target | 18.0+ |
| Xcode | 26.0+ |
| Swift | 6.0 |
| Architecture | MVVM |
| UI Framework | SwiftUI |
| Storage | SwiftData |
| Charts | Swift Charts |

---

## Directory Structure

```
Money Manager/
├── Money_ManagerApp.swift    # App entry point, ModelContainer setup
├── ContentView.swift         # Root view (onboarding flow)
│
├── Models/                   # SwiftData models
│   ├── Transaction.swift    # Core transaction model
│   ├── RecurringTransaction.swift # Recurring transaction model
│   ├── MonthlyBudget.swift  # Monthly budget model
│   ├── CustomCategory.swift # User-created categories
│   ├── PredefinedCategory.swift # Built-in category enum
│   ├── CategorySpending.swift # Computed spending by category
│   ├── Budget.swift         # Budget abstraction
│   └── RecurringDateHelper.swift # Date calculation utilities
│
├── ViewModels/               # @Observable classes (MVVM)
│   ├── OverviewViewModel.swift        # Dashboard state
│   ├── AddTransactionViewModel.swift   # Add/edit transaction
│   ├── BudgetsViewModel.swift          # Budget management
│   ├── RecurringTransactionsViewModel.swift # Recurring transactions
│   ├── ManageCategoriesViewModel.swift # Category CRUD
│   ├── TransactionDetailViewModel.swift # Transaction details
│   └── BackupViewModel.swift           # Export/backup logic
│
├── Pages/                    # Screen-level views
│   ├── MainTabView.swift             # Tab navigation
│   ├── Overview.swift               # Dashboard/home
│   ├── AddTransactionView.swift     # Add/edit transaction form
│   ├── BudgetsView.swift            # Budget management
│   ├── RecurringTransactionsView.swift # Recurring transactions list
│   ├── ManageCategoriesView.swift   # Category management
│   ├── TransactionDetailView.swift  # Transaction details
│   ├── SettingsView.swift           # App settings
│   ├── ExportDataView.swift         # Data export
│   ├── CurrencyPickerView.swift      # Currency selection
│   └── OnboardingView.swift         # First-time user flow
│
├── Components/              # Reusable UI components
│   ├── Budget/              # Budget-related components
│   ├── Category/            # Category components
│   ├── Common/              # Shared components
│   ├── Transaction/         # Transaction input components
│   ├── Recurring/          # Recurring transaction components
│   ├── Transaction/        # Transaction display
│   └── Onboarding/         # Onboarding components
│
├── Services/                # Core services
│   ├── TestData.swift       # Test data generation
│   └── ErrorHandler.swift  # Error handling utilities
│
├── Helpers/                # Utilities
│   ├── AppColors.swift      # Color definitions
│   ├── AppConstants.swift  # App-wide constants
│   └── CategorySeeder.swift # Default category seeding
│
└── Assets.xcassets/         # App assets
```

---

## Data Models

### Core Models (SwiftData @Model)

**Transaction** (`Models/Transaction.swift`)
- Primary data model for all transactions (income and expenses)
- Fields: id, type, amount, category, date, time, description, notes, createdAt, updatedAt, isDeleted
- `type` is "expense" or "income"
- Supports soft delete via `isDeleted` flag
- Supports grouping (groupTransactionId) and settlement linking (settlementId)
- Links to recurring transactions (recurringTransactionId)

**RecurringTransaction** (`Models/RecurringTransaction.swift`)
- Defines recurring transaction patterns
- Supports daily, weekly, monthly, yearly frequencies
- Configurable day-of-week, day-of-month

**MonthlyBudget** (`Models/MonthlyBudget.swift`)
- Stores budget limit per month
- Fields: year, month, limit

**CustomCategory** (`Models/CustomCategory.swift`)
- User-created categories
- Fields: name, icon, color (hex), isHidden

**PredefinedCategory** (`Models/PredefinedCategory.swift`)
- Enum with 15 built-in categories
- Each has icon, color, and key for mapping
- Categories: Food & Dining, Transport, Housing, Health & Medical, Shopping, Utilities, Entertainment, Travel, Work & Professional, Education, Debt & Payments, Books & Media, Family & Kids, Gifts, Other

### Supporting Models

**CategorySpending** (`Models/CategorySpending.swift`)
- Computed model for chart display
- Fields: categoryName, icon, color, amount, percentage

**Transaction** (`Models/Transaction.swift`)
- Simple read-only wrapper for display

---

## ViewModels (@Observable Pattern)

All ViewModels use the modern `@Observable` macro (iOS 17+):

| ViewModel | Purpose |
|-----------|---------|
| `OverviewViewModel` | Dashboard filtering, budget calculation, transaction grouping |
| `AddTransactionViewModel` | Form state, validation, save logic for add/edit transaction |
| `BudgetsViewModel` | Budget CRUD, spending calculations |
| `RecurringTransactionsViewModel` | Recurring transaction management, auto-generation |
| `ManageCategoriesViewModel` | Custom category CRUD operations |
| `TransactionDetailViewModel` | Single transaction view/edit state |
| `BackupViewModel` | CSV/JSON export logic |

---

## State Management Patterns

### SwiftUI Property Wrappers Used
- `@State` - Private view state (must be `private`)
- `@Binding` - Two-way binding for child views
- `@Query` - SwiftData queries for model fetching
- `@AppStorage` - UserDefaults for simple persistence
- `@Environment(\.modelContext)` - SwiftData context injection
- `@Environment(\.dismiss)` - Sheet dismissal

---

## Key Files for Common Tasks

| Task | File(s) |
|------|---------|
| Add transaction | `Pages/AddTransactionView.swift`, `ViewModels/AddTransactionViewModel.swift` |
| View transactions | `Pages/Overview.swift`, `Components/Transaction/TransactionList.swift` |
| Manage budgets | `Pages/BudgetsView.swift`, `ViewModels/BudgetsViewModel.swift` |
| Categories | `Pages/ManageCategoriesView.swift`, `Models/CustomCategory.swift` |
| Recurring transactions | `Pages/RecurringTransactionsView.swift`, `Models/RecurringTransaction.swift` |
| Export data | `Pages/ExportDataView.swift`, `ViewModels/BackupViewModel.swift` |
| App settings | `Pages/SettingsView.swift` |
| Color theme | `Helpers/AppColors.swift` |
| Category definitions | `Models/PredefinedCategory.swift` |

---

## Quick Reference for AI Agents

1. **All SwiftData models** are in `Models/`
2. **All ViewModels** use `@Observable` in `ViewModels/`
3. **Screens** are in `Pages/`, components in `Components/`
4. **Tests** mirror source structure in `Money ManagerTests/`
5. **UI Tests** in `Money ManagerUITests/`
6. **Category colors** defined in `PredefinedCategory.swift`
7. **Color theme** in `AppColors.swift`
8. **Use `CurrencyFormatter`** for amount display

---

## Code Reuse & Shared Components

When adding new code, ALWAYS check existing shared components first to avoid duplication.

### Common Helpers (`Helpers/`)
| File | Purpose |
|------|---------|
| `AppColors.swift` | Brand colors, semantic colors, budget status colors, grays |
| `AppConstants.swift` | Animation durations, quick amounts, formatting, UI measurements, validation |
| `CategorySeeder.swift` | Default category seeding logic |

### Common Components (`Components/Common/`)
| File | Purpose |
|------|---------|
| `CurrencyFormatter.swift` | Currency formatting, symbols, multi-currency support |
| `FloatingActionButton.swift` | Reusable FAB component |
| `EmptyStateView.swift` | Empty state placeholder |
| `MonthSelector.swift` | Month picker |
| `DateFilterSelector.swift` | Date range filter |
| `ViewTypeSelector.swift` | View toggle (daily/monthly) |

### Using Shared Components
- **Colors**: Use `AppColors.accent`, `AppColors.expense`, `AppColors.budgetSafe`, etc.
- **Constants**: Use `AppConstants.Animation.quick`, `AppConstants.UI.cornerRadius`, etc.
- **Currency**: Always use `CurrencyFormatter.format(amount)` for displaying amounts
- **Custom colors**: Use `Color(hex: "...")` from `PredefinedCategory.swift`

### Adding New Shared Code
If new shared code is needed:
1. Check if it belongs in `Helpers/` (constants, utilities) or `Components/Common/` (reusable UI)
2. Update this skill document with the new shared component
3. Document the purpose in code comments

---

## Development Commands

Always use the Makefile for building and testing - do NOT use xcodebuild directly.

### Build
```bash
make build
```

### Running Tests

**IMPORTANT - Test Suite Selection:**
- When fixing/updating/adding test suites, ONLY run that specific test suite to save time and resources:
```bash
make test-one TEST=TransactionTests
make test-one TEST=AddTransactionViewModelTests
```

- Run all unit tests (includes all test suites):
```bash
make test-unit
```

- Run all UI tests (slow - see note below):
```bash
make test-ui
```

**UI Tests Note:**
- UI tests are slow and resource-intensive
- AI agents should NOT run UI tests automatically
- UI tests should be run by the end user manually
- After any test run (unit or UI), ALWAYS check test results from the stored results files in the project folder

**Viewing Test Results:**
- Do NOT use `grep`, `tail`, `head` or similar commands on test output
- Test results are stored in the project folder after each run
- Check the test results directly from the results files

---

## Related Skills

- **swiftui-expert-skill**: For SwiftUI code review and best practices
- **swiftui-pro**: For comprehensive SwiftUI code quality checks
