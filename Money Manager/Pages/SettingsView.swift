import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedCurrency") private var selectedCurrency = "INR"
    @State private var showLoginSheet = false
    @State private var showSignupSheet = false
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                if authService.isAuthenticated {
                    profileSection
                } else {
                    loginPromptSection
                }
                financeSection
                preferencesSection
                if authService.isAuthenticated {
                    accountSection
                }
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showLoginSheet) {
                LoginView(isDismissable: true)
            }
            .sheet(isPresented: $showSignupSheet) {
                SignupView()
            }
            .confirmationDialog("Log Out", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) {
                    authService.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }

    // MARK: - Login Prompt

    private var loginPromptSection: some View {
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
                showLoginSheet = true
            }
            .foregroundStyle(AppColors.accent)

            Button("Create Account") {
                showSignupSheet = true
            }
            .foregroundStyle(AppColors.accent)
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section {
            if let user = authService.currentUser {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppColors.accent.opacity(0.12))
                            .frame(width: 56, height: 56)

                        Text(String(user.username.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.accent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.username)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Finance

    private var financeSection: some View {
        Section("Finance") {
            NavigationLink {
                BudgetsView()
            } label: {
                Label("Budgets", systemImage: "chart.bar.fill")
            }

            NavigationLink {
                RecurringExpensesView()
            } label: {
                Label("Recurring", systemImage: "arrow.clockwise.circle.fill")
            }

            NavigationLink {
                ManageCategoriesView()
            } label: {
                Label("Categories", systemImage: "square.grid.2x2.fill")
            }
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section("Preferences") {
            NavigationLink {
                CurrencyPickerView()
            } label: {
                HStack {
                    Label("Currency", systemImage: "coloncurrencysign.circle")
                    Spacer()
                    Text("\(selectedCurrency) (\(CurrencyFormatter.currentSymbol))")
                        .foregroundStyle(.secondary)
                }
            }

            NavigationLink {
                ExportDataView()
            } label: {
                Label("Backup", systemImage: "archivebox.fill")
            }
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
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
