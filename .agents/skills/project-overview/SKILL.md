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
- Setting up recurring transactions (daily, weekly, monthly, yearly)
- Creating custom categories with colors and icons
- Splitting expenses with groups and tracking settlements
- Offline-first sync with a backend API
- Multi-currency support with CSV export

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
├── Money_ManagerApp.swift        # App entry point, ModelContainer + Environment setup
├── ContentView.swift             # Root view: gates onboarding / login / main app
│
├── Models/                       # SwiftData @Model types
│   ├── Transaction.swift         # Core transaction model (income + expense)
│   ├── RecurringTransaction.swift# Recurring transaction patterns
│   ├── MonthlyBudget.swift       # Monthly budget limit
│   ├── CustomCategory.swift      # User-created categories
│   ├── PredefinedCategory.swift  # Built-in category enum (15 categories)
│   ├── CategorySpending.swift    # Computed spending by category (for charts)
│   ├── GroupModels.swift         # Group, GroupMember, GroupTransaction, GroupBalance
│   ├── AuthToken.swift           # Persisted auth token (SwiftData)
│   ├── PendingChange.swift       # Offline change queue item
│   ├── FailedChange.swift        # Dead-letter queue item
│   └── RecurringDateHelper.swift # Date calculation utilities for recurring transactions
│
├── ViewModels/                   # @Observable @MainActor classes
│   ├── OverviewViewModel.swift           # Dashboard filtering, budget calc, transaction grouping
│   ├── AddTransactionViewModel.swift     # Add/edit transaction form state and validation
│   ├── TransactionsViewModel.swift       # Transactions list state (decoupled from Overview)
│   ├── TransactionDetailViewModel.swift  # Single transaction view/edit state
│   ├── BudgetsViewModel.swift            # Budget CRUD, spending calculations
│   ├── RecurringTransactionsViewModel.swift # Recurring transaction management, auto-generation
│   ├── ManageCategoriesViewModel.swift   # Category list coordination
│   ├── AddCategoryViewModel.swift        # Add category form state
│   ├── CategoryEditorViewModel.swift     # Category edit form state
│   ├── EditCategoryViewModel.swift       # Category edit persistence
│   ├── GroupsListViewModel.swift         # Groups list state
│   ├── GroupDetailViewModel.swift        # Group detail, members, balances, transactions
│   └── BackupViewModel.swift             # Export/import coordination (thin UI layer)
│
├── Pages/                        # Screen-level views
│   ├── MainTabView.swift                 # Tab navigation (uses Tab API, not tabItem)
│   ├── Overview.swift                    # Dashboard/home
│   ├── TransactionsView.swift            # Full transactions list
│   ├── AddTransactionView.swift          # Add/edit transaction form
│   ├── TransactionDetailView.swift       # Transaction details
│   ├── BudgetsView.swift                 # Budget management
│   ├── RecurringTransactionsView.swift   # Recurring transactions list
│   ├── ManageCategoriesView.swift        # Category management
│   ├── ExportDataView.swift              # Data export
│   ├── SettingsView.swift                # App settings
│   ├── CurrencyPickerView.swift          # Currency selection
│   ├── OnboardingView.swift              # First-time user flow (6 pages)
│   ├── LoginView.swift                   # Login screen
│   ├── SignupView.swift                  # Signup with invite code
│   ├── SyncDebugView.swift               # Debug view for sync state
│   │
│   │   # Groups feature
│   ├── GroupsListView.swift              # Groups list with search + create FAB
│   ├── GroupDetailView.swift             # Group detail, members, activity
│   ├── CreateGroupSheet.swift            # Create group sheet
│   ├── AddMemberSheet.swift              # Add member to group
│   ├── RecordSettlementView.swift        # Record a settlement between members
│   ├── GroupsLockedView.swift            # Feature-locked placeholder
│   │
│   │   # Group sub-components (in Pages/)
│   ├── GroupRow.swift
│   ├── GroupHeaderStats.swift
│   ├── GroupMemberRow.swift
│   ├── GroupBalanceRow.swift
│   ├── GroupTransactionRow.swift
│   ├── GroupTransactionDetailSheet.swift
│   ├── ActivityRow.swift
│   └── NetBalanceCard.swift
│
├── Components/                   # Reusable UI components
│   ├── Common/
│   │   ├── CurrencyFormatter.swift       # Currency formatting and symbols
│   │   ├── EmptyStateView.swift          # Empty state placeholder
│   │   ├── FloatingActionButton.swift    # Reusable FAB
│   │   ├── MonthSelector.swift           # Month picker
│   │   ├── DateFilterSelector.swift      # Date range filter
│   │   ├── ViewTypeSelector.swift        # View toggle (daily/monthly)
│   │   ├── SyncStatusView.swift          # Online/sync status indicator
│   │   └── RecurringDetailsSheet.swift   # Recurring transaction detail sheet
│   │
│   ├── Transaction/
│   │   ├── TransactionList.swift
│   │   ├── TransactionRow.swift
│   │   ├── GroupTransactionContent.swift # Transaction content variant for groups
│   │   ├── CategoryPickerView.swift
│   │   ├── CategoryPickerRow.swift
│   │   ├── QuickAmountButton.swift
│   │   ├── QuickDateButton.swift
│   │   ├── DatePickerSheet.swift
│   │   └── TimePickerSheet.swift
│   │
│   ├── Budget/
│   │   ├── BudgetCard.swift
│   │   ├── BudgetOverviewCard.swift
│   │   ├── BudgetSheet.swift
│   │   ├── BudgetStatusBanner.swift
│   │   ├── NoBudgetCard.swift
│   │   └── SpendingSummaryCard.swift
│   │
│   ├── Recurring/
│   │   ├── RecurringTransactionRow.swift
│   │   ├── AddRecurringTransactionSheet.swift
│   │   └── EditRecurringTransactionSheet.swift
│   │
│   ├── Category/
│   │   ├── CategoryRow.swift
│   │   ├── CategoryChart.swift
│   │   ├── CategoryEditorView.swift
│   │   ├── AddCategorySheet.swift
│   │   └── EditCategorySheet.swift
│   │
│   └── Onboarding/
│       └── OnboardingPageView.swift      # Individual onboarding page with illustration card
│
├── Services/                     # Core business logic and networking
│   ├── ServiceFactory.swift              # DI factory — swaps real/mock services by environment
│   ├── TestData.swift                    # Test data generation
│   ├── PersistenceService.swift          # SwiftData persistence helpers
│   ├── RecurringTransactionService.swift # Recurring transaction generation logic
│   ├── ExportService.swift               # CSV export logic
│   ├── ImportService.swift               # CSV import logic
│   │
│   ├── Auth/
│   │   ├── AuthService.swift             # Login, signup, token management
│   │   ├── MockAuthService.swift
│   │   └── SessionStore.swift            # Persisted session state
│   │
│   ├── Networking/
│   │   ├── APIClient.swift               # URLSession-based HTTP client
│   │   ├── APIModels.swift               # Codable API request/response models (API prefix)
│   │   ├── APIError.swift                # Typed API errors
│   │   ├── GroupService.swift            # Group CRUD API calls
│   │   └── MockGroupService.swift
│   │
│   ├── Sync/
│   │   ├── SyncService.swift             # Offline-first sync orchestration
│   │   ├── MockSyncService.swift
│   │   ├── ChangeQueueManager.swift      # Pending/failed change queue
│   │   ├── MockChangeQueueManager.swift
│   │   ├── ModelMapper.swift             # API model ↔ SwiftData model mapping
│   │   └── NetworkMonitor.swift          # Reachability monitoring
│   │
│   └── Protocols/
│       ├── AuthServiceProtocol.swift
│       ├── SyncServiceProtocol.swift
│       ├── ChangeQueueManagerProtocol.swift
│       └── GroupServiceProtocol.swift
│
├── Helpers/                      # Utilities and constants
│   ├── AppColors.swift           # Brand, semantic, budget status, and background colors
│   ├── AppConstants.swift        # Animation durations, quick amounts, UI measurements, validation
│   ├── AppEnvironment.swift      # @Environment keys for injected services
│   ├── AppLogger.swift           # Structured logging (replaces ErrorHandler)
│   ├── AppRoute.swift            # NavigationStack route enum
│   ├── AppTypography.swift       # Shared text styles
│   ├── CategoryResolver.swift    # O(1) category lookup by ID
│   └── CategorySeeder.swift      # Default category seeding
│
└── Assets.xcassets/
```

---

## Data Models

### SwiftData Models (`@Model`)

**Transaction** (`Models/Transaction.swift`)
- Primary model for all transactions (income and expenses)
- `kind: TransactionKind` enum — `.income` or `.expense` (not a raw String)
- Fields: id, kind, amount (Double), categoryId, date, description, notes, createdAt, updatedAt, isDeleted
- Soft delete via `isDeleted` flag
- Group linking: `groupTransactionId`, `group_id`
- Settlement linking: `settlementId`
- Recurring linking: `recurringTransactionId`

**RecurringTransaction** (`Models/RecurringTransaction.swift`)
- `frequency: RecurringFrequency` enum — `.daily`, `.weekly`, `.monthly`, `.yearly` (not a raw String)
- Configurable day-of-week, day-of-month, nextOccurrence

**MonthlyBudget** (`Models/MonthlyBudget.swift`)
- Fields: year, month, limit (Double)

**CustomCategory** (`Models/CustomCategory.swift`)
- Fields: id, name, icon, colorHex, isHidden

**GroupModels** (`Models/GroupModels.swift`)
- `SplitGroupModel` — group entity with members, transactions, balances
- `GroupMemberModel` — member with email, username, joinDate
- `GroupTransactionModel` — group-specific transaction
- `GroupBalanceModel` — who owes whom

**AuthToken** (`Models/AuthToken.swift`)
- Persisted login token (SwiftData, not Keychain)

**PendingChange / FailedChange** (`Models/PendingChange.swift`, `FailedChange.swift`)
- Offline change queue items for the sync system

### Supporting Models

**PredefinedCategory** (`Models/PredefinedCategory.swift`)
- Enum with 15 built-in categories, each with icon, colorHex, and key
- Categories: Food & Dining, Transport, Housing, Health & Medical, Shopping, Utilities, Entertainment, Travel, Work & Professional, Education, Debt & Payments, Books & Media, Family & Kids, Gifts, Other

**CategorySpending** (`Models/CategorySpending.swift`)
- Read-only struct for chart display: categoryName, icon, color, amount, percentage

---

## ViewModels (`@Observable` Pattern)

All ViewModels use `@Observable` (iOS 17+) and are marked `@MainActor`.

| ViewModel | Purpose |
|-----------|---------|
| `OverviewViewModel` | Dashboard filtering, budget calc, transaction grouping |
| `AddTransactionViewModel` | Form state, validation, save/edit logic |
| `TransactionsViewModel` | Transactions tab list state (separate from Overview) |
| `TransactionDetailViewModel` | Single transaction view/edit |
| `BudgetsViewModel` | Budget CRUD, spending calculations |
| `RecurringTransactionsViewModel` | Recurring transaction management, auto-generation |
| `ManageCategoriesViewModel` | Category list coordination |
| `AddCategoryViewModel` | Add category form state |
| `CategoryEditorViewModel` | Edit category form state |
| `EditCategoryViewModel` | Edit category persistence |
| `GroupsListViewModel` | Groups list, search, create |
| `GroupDetailViewModel` | Group detail, members, balances, activity feed |
| `BackupViewModel` | Thin UI coordinator for export/import |

---

## Services Layer

Services are injected via SwiftUI `@Environment` — never accessed as globals.

| Service | Purpose |
|---------|---------|
| `AuthService` / `MockAuthService` | Login, signup, logout, token refresh |
| `SessionStore` | Persisted auth state (current user, last email) |
| `SyncService` / `MockSyncService` | Offline-first sync — pushes pending changes when online |
| `ChangeQueueManager` / `MockChangeQueueManager` | Enqueues/dequeues pending and failed changes |
| `GroupService` / `MockGroupService` | Group CRUD, member management, settlement API calls |
| `RecurringTransactionService` | Auto-generates recurring transactions offline |
| `ExportService` | CSV export logic |
| `ImportService` | CSV import logic |
| `PersistenceService` | SwiftData context helpers |
| `ServiceFactory` | Creates real or mock services based on environment |

`ServiceFactory` detects the test environment via launch arguments and wires mock services automatically — no `#if DEBUG` needed in view code.

---

## State Management Patterns

### SwiftUI Property Wrappers Used
- `@State` — Private view state (always `private`)
- `@Binding` — Two-way binding for child views that need to modify parent state
- `@Bindable` — iOS 17+: injected `@Observable` needing two-way bindings
- `@Query` — SwiftData queries for model fetching
- `@AppStorage` — UserDefaults for simple persistence (e.g. `hasCompletedOnboarding`)
- `@Environment(\.modelContext)` — SwiftData context injection
- `@Environment(\.dismiss)` — Sheet dismissal
- `@Environment(AuthServiceProtocol.self)` — Injected services (auth, sync, changeQueue)

### Dependency Injection
All services are injected through `.environment()` at the app root (`Money_ManagerApp.swift`). ViewModels receive services via initializer injection — never via global singletons.

---

## Key Files for Common Tasks

| Task | File(s) |
|------|---------|
| Add/edit transaction | `Pages/AddTransactionView.swift`, `ViewModels/AddTransactionViewModel.swift` |
| View transactions | `Pages/TransactionsView.swift`, `ViewModels/TransactionsViewModel.swift` |
| Dashboard/overview | `Pages/Overview.swift`, `ViewModels/OverviewViewModel.swift` |
| Manage budgets | `Pages/BudgetsView.swift`, `ViewModels/BudgetsViewModel.swift` |
| Categories | `Pages/ManageCategoriesView.swift`, `Models/CustomCategory.swift` |
| Recurring transactions | `Pages/RecurringTransactionsView.swift`, `Models/RecurringTransaction.swift` |
| Groups & splitting | `Pages/GroupsListView.swift`, `Pages/GroupDetailView.swift`, `ViewModels/GroupsListViewModel.swift` |
| Auth / login | `Pages/LoginView.swift`, `Pages/SignupView.swift`, `Services/Auth/AuthService.swift` |
| Sync | `Services/Sync/SyncService.swift`, `Services/Sync/ChangeQueueManager.swift` |
| Export data | `Pages/ExportDataView.swift`, `Services/ExportService.swift` |
| App settings | `Pages/SettingsView.swift` |
| Color theme | `Helpers/AppColors.swift` |
| Navigation routes | `Helpers/AppRoute.swift` |
| Environment keys | `Helpers/AppEnvironment.swift` |
| Category lookup | `Helpers/CategoryResolver.swift` |
| Logging | `Helpers/AppLogger.swift` |
| Category definitions | `Models/PredefinedCategory.swift` |
| Onboarding | `Pages/OnboardingView.swift`, `Components/Onboarding/OnboardingPageView.swift` |

---

## Quick Reference for AI Agents

1. **All SwiftData models** are in `Models/`
2. **All ViewModels** use `@Observable @MainActor` in `ViewModels/`
3. **Screens** are in `Pages/`, reusable components in `Components/`
4. **Services** are in `Services/` and injected via `@Environment` — never global
5. **Tests** mirror source structure in `Money ManagerTests/`
6. **UI Tests** in `Money ManagerUITests/` — never run automatically
7. **Transaction type** is `TransactionKind` enum (`.income`/`.expense`), not a String
8. **Recurring frequency** is `RecurringFrequency` enum, not a String
9. **Category colors** defined in `PredefinedCategory.swift`; use `CategoryResolver` for O(1) lookup
10. **Always use `CurrencyFormatter`** for amount display — never format amounts manually

---

## Code Reuse & Shared Components

When adding new code, ALWAYS check existing shared components first to avoid duplication.

### Common Helpers (`Helpers/`)
| File | Purpose |
|------|---------|
| `AppColors.swift` | Brand colors, semantic colors, budget status colors, grays |
| `AppConstants.swift` | Animation durations, quick amounts, formatting, UI measurements, validation |
| `AppLogger.swift` | Structured logging — use instead of `print()` |
| `AppRoute.swift` | Typed navigation routes for NavigationStack |
| `AppEnvironment.swift` | `@Environment` keys for injected services |
| `AppTypography.swift` | Shared text styles |
| `CategoryResolver.swift` | O(1) category lookup by ID |
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
| `SyncStatusView.swift` | Online/sync status indicator |
| `RecurringDetailsSheet.swift` | Recurring transaction details sheet |

### Using Shared Components
- **Colors**: Use `AppColors.accent`, `AppColors.expense`, `AppColors.budgetSafe`, etc.
- **Constants**: Use `AppConstants.Animation.quick`, `AppConstants.UI.cornerRadius`, etc.
- **Currency**: Always use `CurrencyFormatter.format(amount)` for displaying amounts
- **Logging**: Use `AppLogger` — never `print()`
- **Navigation**: Use `AppRoute` cases with `NavigationStack`/`navigationDestination(for:)`

---

## Development Commands

Always use the Makefile — do NOT run `xcodebuild` directly.

```bash
make build                          # Build the project
make test-unit                      # Run all unit tests
make test-one TEST=SomeTestClass    # Run a single test suite (preferred when working on specific tests)
make test-ui                        # Run UI tests (slow — never run automatically)
make test                           # Run everything (unit + API + UI)
make coverage                       # View coverage summary
make release                        # Build a Simulator release zip locally (for testing before tagging)
make clean                          # Clean build artifacts
make screenshots                    # Capture all screens → copies PNGs to Screenshots/
make screenshot-one TAG=overview    # Capture a single screen by tag
```

### Test Output Handling

**IMPORTANT**: Never use `head`, `grep`, or `tail` on test output. Always parse the xcresult file:

```bash
xcrun xcresulttool get object --legacy --path ./test_results.xcresult --format json
```

### UI Tests Note
- UI tests are slow and resource-intensive
- AI agents must NOT run UI tests automatically — leave them for the user to run manually
- Screenshots require the backend to be reachable and the test account (`ankush@gmail.com`) to exist

---

## Related Skills

- **swiftui-expert-skill**: For SwiftUI code review and best practices
- **swiftui-pro**: For comprehensive SwiftUI code quality checks
