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
    @Environment(\.networkMonitor) private var networkMonitor
    @AppStorage(UserDefaults.Keys.selectedCurrency.rawValue) private var selectedCurrency = "INR"
    @State private var authVersion = 0
    @State private var lastKnownAuthState: Bool? = nil
    @State private var navigationPath: [SettingsRoute] = []
    @State private var showLoginSheet = false
    @State private var showSignupSheet = false
    @State private var showLogoutConfirmation = false
    @State private var showEditProfile = false
    @State private var isSyncingManually = false
    #if DEBUG
    @State private var showSyncDebug = false
    #endif

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: AppConstants.UI.spacing20) {
                    // Profile / login card
                    if authService.isAuthenticated, let user = authService.currentUser {
                        if !user.emailVerified {
                            UnverifiedEmailBanner(email: user.email)
                        }
                        ProfileCard(
                            username: user.username,
                            email: user.email,
                            onEditProfile: { showEditProfile = true },
                            onLogOut: { showLogoutConfirmation = true }
                        )
                    } else {
                        LoginPromptCard(
                            onSignIn: { showLoginSheet = true },
                            onCreateAccount: { showSignupSheet = true }
                        )
                    }

                    // Finance section
                    SettingsSection(header: "FINANCE") {
                        SettingsNavRow(
                            icon: AppIcons.UI.budget,
                            iconBg: AppColors.primary,
                            label: "Budgets",
                            accessibilityID: "settings.budgets-row",
                            onTap: { navigationPath.append(.budgets) }
                        )
                        Divider().padding(.leading, 56)
                        SettingsNavRow(
                            icon: AppIcons.UI.recurring,
                            iconBg: AppColors.primary,
                            label: "Recurring",
                            accessibilityID: "settings.recurring-row",
                            onTap: { navigationPath.append(.recurring) }
                        )
                        Divider().padding(.leading, 56)
                        SettingsNavRow(
                            icon: AppIcons.UI.categories,
                            iconBg: Color("CatIndigo", bundle: .main),
                            label: "Categories",
                            accessibilityID: "settings.categories-row",
                            onTap: { navigationPath.append(.categories) }
                        )
                    }

                    // Preferences section
                    SettingsSection(header: "PREFERENCES") {
                        SettingsNavRow(
                            icon: AppIcons.UI.currency,
                            iconBg: AppColors.income,
                            label: "Currency",
                            trailingText: "\(selectedCurrency) (\(CurrencyFormatter.currentSymbol))",
                            accessibilityID: "settings.currency-row",
                            onTap: { navigationPath.append(.currency) }
                        )

                        Divider().padding(.leading, 56)

                        SettingsNavRow(
                            icon: AppIcons.UI.export,
                            iconBg: Color("CatBlue", bundle: .main),
                            label: "Backup",
                            accessibilityID: "settings.backup-row",
                            onTap: { navigationPath.append(.backup) }
                        )
                    }

                    // Sync section (authenticated only)
                    if authService.isAuthenticated {
                        SettingsSection(header: "SYNC") {
                            SyncRow(
                                isSyncing: isSyncingManually || syncService.isSyncing,
                                isConnected: networkMonitor.isConnected,
                                onSyncNow: {
                                    isSyncingManually = true
                                    Task {
                                        await syncService.fullSync()
                                        isSyncingManually = false
                                    }
                                }
                            )
                        }
                    }

                    #if DEBUG
                    SettingsSection(header: "DEBUG") {
                        SettingsNavRow(
                            icon: AppIcons.UI.sync,
                            iconBg: AppColors.warning,
                            label: "Sync Debug",
                            onTap: { navigationPath.append(.syncDebug) }
                        )
                    }
                    #endif

                    // Footer
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                    Text("Paisa v\(version) · Made with ♥")
                        .font(AppTypography.caption1)
                        .foregroundStyle(AppColors.label3)
                        .padding(.bottom, AppConstants.UI.spacingSM)
                }
                .padding(.horizontal, AppConstants.UI.padding)
                .padding(.top, AppConstants.UI.spacing12)
                .padding(.bottom, AppConstants.UI.spacingXL)
            }
            .background(AppColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                #if DEBUG
                if ProcessInfo.processInfo.isUITesting,
                   let routeName = ProcessInfo.processInfo.environment["SETTINGS_ROUTE"] {
                    let route: SettingsRoute? = switch routeName {
                    case "budgets":    .budgets
                    case "recurring":  .recurring
                    case "categories": .categories
                    case "currency":   .currency
                    case "backup":     .backup
                    default:           nil
                    }
                    if let route { navigationPath = [route] }
                }
                #endif
            }
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
            .sheet(isPresented: $showLoginSheet) { LoginView(isDismissable: true) }
            .sheet(isPresented: $showSignupSheet) { SignupView() }
            .sheet(isPresented: $showEditProfile) {
                if let user = authService.currentUser {
                    EditProfileView(currentUsername: user.username, currentEmail: user.email)
                }
            }
            .alert("Log Out", isPresented: $showLogoutConfirmation) {
                Button("Log Out", role: .destructive) { authService.logout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?")
            }
            .onReceive(NotificationCenter.default.publisher(for: .authStateDidChange)) { _ in
                let isNowAuthenticated = authService.isAuthenticated
                if lastKnownAuthState != isNowAuthenticated {
                    lastKnownAuthState = isNowAuthenticated
                    #if DEBUG
                    // During screenshot runs the auth state is pre-established; don't
                    // blow away the NavigationStack on every background sync notification.
                    if ProcessInfo.processInfo.isScreenshotMode { return }
                    #endif
                    navigationPath = []
                    authVersion += 1
                }
            }
        }
        .id(authVersion)
    }
}

// MARK: - Shared card container

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }
}

// MARK: - Section with header label

private struct SettingsSection<Content: View>: View {
    let header: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
            Text(header)
                .font(AppTypography.footnote)
                .fontWeight(.semibold)
                .tracking(AppTypography.trackingFootnote)
                .foregroundStyle(AppColors.label2)
                .padding(.leading, AppConstants.UI.spacingXS)
            SettingsCard { content }
        }
    }
}

// MARK: - Rounded icon badge

private struct IconBadge: View {
    let name: String
    let bg: Color
    var size: CGFloat = AppConstants.UI.iconBadgeSize

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppConstants.UI.radius10)
                .fill(bg)
                .frame(width: size, height: size)
            AppIcon(name: name, size: size * 0.50, color: .white)
        }
    }
}

// MARK: - Nav row helper

private struct SettingsNavRow: View {
    let icon: String
    let iconBg: Color
    let label: String
    var trailingText: String? = nil
    var accessibilityID: String? = nil
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppConstants.UI.spacing12) {
                IconBadge(name: icon, bg: iconBg)
                Text(label)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.label)
                Spacer()
                if let trailingText {
                    Text(trailingText)
                        .font(AppTypography.subhead)
                        .foregroundStyle(AppColors.label2)
                }
                AppIcon(name: AppIcons.UI.chevron, size: 16, color: AppColors.label3)
            }
            .padding(.horizontal, AppConstants.UI.padding)
            .padding(.vertical, AppConstants.UI.spacing14)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityID ?? "")
    }
}

// MARK: - Profile card

private struct ProfileCard: View {
    let username: String
    let email: String
    let onEditProfile: () -> Void
    let onLogOut: () -> Void

    var body: some View {
        SettingsCard {
            // Profile row
            Button(action: onEditProfile) {
                HStack(spacing: AppConstants.UI.spacing12) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryBg)
                            .frame(width: AppConstants.UI.profileAvatarSize, height: AppConstants.UI.profileAvatarSize)
                        Text(String(username.prefix(1)).uppercased())
                            .font(AppTypography.title3)
                            .foregroundStyle(AppColors.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(username)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.label)
                        Text(email)
                            .font(AppTypography.subhead)
                            .foregroundStyle(AppColors.label2)
                    }
                    Spacer()
                    AppIcon(name: AppIcons.UI.chevron, size: 16, color: AppColors.label3)
                }
                .padding(.horizontal, AppConstants.UI.padding)
                .padding(.vertical, AppConstants.UI.spacing14)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.edit-profile-button")

            Divider()

            // Log out row
            Button(action: onLogOut) {
                HStack(spacing: AppConstants.UI.spacingSM) {
                    AppIcon(name: AppIcons.UI.logout, size: 20, color: AppColors.expense)
                    Text("Log Out")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.expense)
                }
                .padding(.horizontal, AppConstants.UI.padding)
                .padding(.vertical, AppConstants.UI.spacing14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Login prompt card

private struct LoginPromptCard: View {
    let onSignIn: () -> Void
    let onCreateAccount: () -> Void

    var body: some View {
        SettingsCard {
            HStack(spacing: AppConstants.UI.spacing12) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryBg)
                        .frame(width: AppConstants.UI.profileAvatarSize, height: AppConstants.UI.profileAvatarSize)
                    AppIcon(name: AppIcons.UI.profile, size: 22, color: AppColors.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Guest Mode")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.label)
                    Text("Sign in to sync across devices")
                        .font(AppTypography.subhead)
                        .foregroundStyle(AppColors.label2)
                }
                Spacer()
            }
            .padding(.horizontal, AppConstants.UI.padding)
            .padding(.vertical, AppConstants.UI.spacing14)

            Divider()

            Button(action: onSignIn) {
                Text("Sign In")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppConstants.UI.padding)
                    .padding(.vertical, AppConstants.UI.spacing14)
            }
            .buttonStyle(.plain)

            Divider()

            Button(action: onCreateAccount) {
                Text("Create Account")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppConstants.UI.padding)
                    .padding(.vertical, AppConstants.UI.spacing14)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Sync row

private struct SyncRow: View {
    let isSyncing: Bool
    let isConnected: Bool
    let onSyncNow: () -> Void

    var body: some View {
        Button(action: onSyncNow) {
            HStack(spacing: AppConstants.UI.spacing12) {
                IconBadge(name: AppIcons.UI.sync, bg: Color("CatDark", bundle: .main))
                SyncStatusView()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, AppConstants.UI.padding)
            .padding(.vertical, AppConstants.UI.spacing14)
        }
        .buttonStyle(.plain)
        .disabled(isSyncing || !isConnected)
    }
}

// MARK: - Unverified email banner

private struct UnverifiedEmailBanner: View {
    let email: String
    @Environment(\.authService) private var authService
    @State private var showVerification = false

    var body: some View {
        SettingsCard {
            Button {
                showVerification = true
            } label: {
                HStack(spacing: AppConstants.UI.spacing12) {
                    AppIcon(name: AppIcons.UI.warningIcon, size: 22, color: AppColors.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email not verified")
                            .font(AppTypography.subhead)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.label)
                        Text("Tap to verify \(email)")
                            .font(AppTypography.caption1)
                            .foregroundStyle(AppColors.label2)
                    }
                    Spacer()
                    AppIcon(name: AppIcons.UI.chevron, size: 16, color: AppColors.label3)
                }
                .padding(.horizontal, AppConstants.UI.padding)
                .padding(.vertical, AppConstants.UI.spacing14)
            }
            .buttonStyle(.plain)
        }
        .fullScreenCover(isPresented: $showVerification) {
            EmailVerificationView(email: email)
        }
    }
}

#Preview {
    SettingsView()
}
