---
name: project-overview
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
- Tracking expenses with categories, descriptions, and timestamps
- Managing monthly budgets with real-time progress
- Setting up recurring expenses (daily, weekly, monthly)
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
│   ├── Expense.swift        # Core expense model
│   ├── RecurringExpense.swift # Recurring expense model
│   ├── MonthlyBudget.swift  # Monthly budget model
│   ├── CustomCategory.swift # User-created categories
│   ├── PredefinedCategory.swift # Built-in category enum
│   ├── CategorySpending.swift # Computed spending by category
│   ├── Budget.swift         # Budget abstraction
│   ├── Transaction.swift    # Simple transaction wrapper
│   └── RecurringDateHelper.swift # Date calculation utilities
│
├── ViewModels/               # @Observable classes (MVVM)
│   ├── OverviewViewModel.swift        # Dashboard state
│   ├── AddExpenseViewModel.swift       # Add/edit expense
│   ├── BudgetsViewModel.swift          # Budget management
│   ├── RecurringExpensesViewModel.swift # Recurring expenses
│   ├── ManageCategoriesViewModel.swift # Category CRUD
│   ├── TransactionDetailViewModel.swift # Expense details
│   └── BackupViewModel.swift           # Export/backup logic
│
├── Pages/                    # Screen-level views
│   ├── MainTabView.swift             # Tab navigation
│   ├── Overview.swift               # Dashboard/home
│   ├── AddExpenseView.swift         # Add/edit expense form
│   ├── BudgetsView.swift            # Budget management
│   ├── RecurringExpensesView.swift  # Recurring expenses list
│   ├── ManageCategoriesView.swift   # Category management
│   ├── TransactionDetailView.swift  # Expense details
│   ├── SettingsView.swift           # App settings
│   ├── ExportDataView.swift         # Data export
│   ├── CurrencyPickerView.swift      # Currency selection
│   └── OnboardingView.swift         # First-time user flow
│
├── Components/              # Reusable UI components
│   ├── Budget/              # Budget-related components
│   ├── Category/            # Category components
│   ├── Common/              # Shared components
│   ├── Expense/             # Expense input components
│   ├── Recurring/          # Recurring expense components
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

**Expense** (`Models/Expense.swift`)
- Primary data model for all expenses
- Fields: id, amount, category, date, time, description, notes, createdAt, updatedAt, isDeleted
- Supports soft delete via `isDeleted` flag
- Supports grouping (groupId, groupName)
- Links to recurring expenses (recurringExpenseId)

**RecurringExpense** (`Models/RecurringExpense.swift`)
- Defines recurring expense patterns
- Supports daily, weekly, monthly, yearly frequencies
- Configurable day-of-week, day-of-month
- Skip weekends option

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
| `OverviewViewModel` | Dashboard filtering, budget calculation, expense grouping |
| `AddExpenseViewModel` | Form state, validation, save logic for add/edit expense |
| `BudgetsViewModel` | Budget CRUD, spending calculations |
| `RecurringExpensesViewModel` | Recurring expense management, auto-generation |
| `ManageCategoriesViewModel` | Custom category CRUD operations |
| `TransactionDetailViewModel` | Single expense view/edit state |
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
| Add expense | `Pages/AddExpenseView.swift`, `ViewModels/AddExpenseViewModel.swift` |
| View expenses | `Pages/Overview.swift`, `Components/Transaction/TransactionList.swift` |
| Manage budgets | `Pages/BudgetsView.swift`, `ViewModels/BudgetsViewModel.swift` |
| Categories | `Pages/ManageCategoriesView.swift`, `Models/CustomCategory.swift` |
| Recurring expenses | `Pages/RecurringExpensesView.swift`, `Models/RecurringExpense.swift` |
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

## Related Skills

- **swiftui-expert-skill**: For SwiftUI code review and best practices
- **swiftui-pro**: For comprehensive SwiftUI code quality checks
