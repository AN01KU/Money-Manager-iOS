import SwiftUI
import SwiftData

private enum SettingsRoute: Hashable {
    case budgets
    case recurring
    case categories
    case currency
    case backup
    #if DEBUG
    case syncDebug
    #endif
}

struct SettingsView: View {
    @Environment(\.authService) private var authService
    @Environment(\.syncService) private var syncService
    @Environment(\.changeQueueManager) private var changeQueueManager
    @AppStorage("selectedCurrency") private var selectedCurrency = "INR"
    @State private var showLoginSheet = false
    @State private var showSignupSheet = false
    @State private var showLogoutConfirmation = false
    @State private var showEditProfile = false
    @State private var isSyncingManually = false
    #if DEBUG
    @State private var showSyncDebug = false
    #endif

    var body: some View {
        NavigationStack {
            List {
                if authService.isAuthenticated {
                    if let user = authService.currentUser {
                        ProfileSection(
                            username: user.username,
                            email: user.email,
                            onEditProfile: { showEditProfile = true },
                            onLogOut: { showLogoutConfirmation = true }
                        )
                    }
                } else {
                    LoginPromptSection(
                        onSignIn: { showLoginSheet = true },
                        onCreateAccount: { showSignupSheet = true }
                    )
                }
                FinanceSection()
                PreferencesSection(
                    selectedCurrency: selectedCurrency,
                    currencySymbol: CurrencyFormatter.currentSymbol
                )
                if authService.isAuthenticated {
                    SyncSection(
                        pendingCount: changeQueueManager.pendingCount,
                        failedCount: changeQueueManager.failedCount,
                        isSyncing: isSyncingManually || syncService.isSyncing,
                        isNetworkConnected: NetworkMonitor.shared.isConnected,
                        onSyncNow: {
                            isSyncingManually = true
                            Task {
                                await syncService.fullSync()
                                isSyncingManually = false
                            }
                        }
                    )
                }
                #if DEBUG
                DebugSection()
                #endif
                AboutSection()
            }
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .budgets:    BudgetsView()
                case .recurring:  RecurringTransactionsView()
                case .categories: ManageCategoriesView()
                case .currency:   CurrencyPickerView()
                case .backup:     ExportDataView()
                #if DEBUG
                case .syncDebug:  SyncDebugView()
                #endif
                }
            }
            .sheet(isPresented: $showLoginSheet) {
                LoginView(isDismissable: true)
            }
            .sheet(isPresented: $showSignupSheet) {
                SignupView()
            }
            .sheet(isPresented: $showEditProfile) {
                if let user = authService.currentUser {
                    EditProfileView(currentUsername: user.username, currentEmail: user.email)
                }
            }
            .alert("Log Out", isPresented: $showLogoutConfirmation) {
                Button("Log Out", role: .destructive) {
                    authService.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

// MARK: - Login Prompt

private struct LoginPromptSection: View {
    let onSignIn: () -> Void
    let onCreateAccount: () -> Void

    var body: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppColors.accent.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title2)
                        .foregroundStyle(AppColors.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Guest Mode")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Sign in to sync across devices")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            Button("Sign In") {
                onSignIn()
            }
            .foregroundStyle(AppColors.accent)

            Button("Create Account") {
                onCreateAccount()
            }
            .foregroundStyle(AppColors.accent)
        }
    }
}

// MARK: - Profile

private struct ProfileSection: View {
    let username: String
    let email: String
    let onEditProfile: () -> Void
    let onLogOut: () -> Void

    var body: some View {
        Section {
            Button(action: onEditProfile) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppColors.accent.opacity(0.12))
                            .frame(width: 56, height: 56)

                        Text(String(username.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.accent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(username)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.edit-profile-button")

            Button(role: .destructive) {
                onLogOut()
            } label: {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }
}

// MARK: - Finance

private struct FinanceSection: View {
    var body: some View {
        Section("Finance") {
            NavigationLink(value: SettingsRoute.budgets) {
                Label("Budgets", systemImage: "chart.bar.fill")
            }
            .accessibilityIdentifier("settings.budgets-row")

            NavigationLink(value: SettingsRoute.recurring) {
                Label("Recurring", systemImage: "arrow.clockwise.circle.fill")
            }
            .accessibilityIdentifier("settings.recurring-row")

            NavigationLink(value: SettingsRoute.categories) {
                Label("Categories", systemImage: "square.grid.2x2.fill")
            }
            .accessibilityIdentifier("settings.categories-row")
        }
    }
}

// MARK: - Preferences

private struct PreferencesSection: View {
    let selectedCurrency: String
    let currencySymbol: String

    var body: some View {
        Section("Preferences") {
            NavigationLink(value: SettingsRoute.currency) {
                HStack {
                    Label("Currency", systemImage: "coloncurrencysign.circle")
                    Spacer()
                    Text("\(selectedCurrency) (\(currencySymbol))")
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("settings.currency-row")

            NavigationLink(value: SettingsRoute.backup) {
                Label("Backup", systemImage: "archivebox.fill")
            }
            .accessibilityIdentifier("settings.backup-row")
        }
    }
}

// MARK: - Sync

private struct SyncSection: View {
    let pendingCount: Int
    let failedCount: Int
    let isSyncing: Bool
    let isNetworkConnected: Bool
    let onSyncNow: () -> Void

    var body: some View {
        Section("Sync") {
            SyncStatusView()
                .frame(maxWidth: .infinity, alignment: .leading)

            if pendingCount > 0 {
                HStack {
                    Text("Pending changes")
                    Spacer()
                    Text("\(pendingCount)")
                        .foregroundStyle(.secondary)
                }
            }

            if failedCount > 0 {
                HStack {
                    Text("Failed changes")
                    Spacer()
                    Text("\(failedCount)")
                        .foregroundStyle(.red)
                }
            }

            Button {
                onSyncNow()
            } label: {
                HStack {
                    Label("Sync Now", systemImage: "arrow.clockwise.icloud")
                    if isSyncing {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isSyncing || !isNetworkConnected)
        }
    }
}

// MARK: - Debug (DEBUG builds only)

#if DEBUG
private struct DebugSection: View {
    var body: some View {
        Section {
            NavigationLink(value: SettingsRoute.syncDebug) {
                Label("Sync Debug", systemImage: "antenna.radiowaves.left.and.right")
            }
        } header: {
            Text("Debug")
        }
    }
}
#endif

// MARK: - About

private struct AboutSection: View {
    var body: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
}
