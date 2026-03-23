import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedCurrency") private var selectedCurrency = "INR"
    @State private var showLogoutConfirmation = false
    @State private var isSyncing = false
    
    var body: some View {
        NavigationStack {
            List {
                accountSection
                #if DEBUG
                syncSection
                #endif
                financeSection
                preferencesSection
                aboutSection
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Logout",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Logout", role: .destructive) {
                    logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to logout? Your data will remain on this device.")
            }
        }
    }
    
    // MARK: - Account
    
    private var accountSection: some View {
        Section("Account") {
            if let user = authService.currentUser {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundStyle(AppColors.accent)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.username)
                            .font(.headline)
                        Text(user.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }
    
    // MARK: - Sync
    
    private var syncSection: some View {
        Section("Sync") {
            HStack {
                Label("Status", systemImage: "arrow.triangle.2.circlepath")
                Spacer()
                if syncService.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Syncing...")
                        .foregroundStyle(.secondary)
                } else if NetworkMonitor.shared.isConnected {
                    Label("Connected", systemImage: "wifi")
                        .foregroundStyle(AppColors.positive)
                        .font(.caption)
                } else {
                    Label("Offline", systemImage: "wifi.slash")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
            
            if let lastSync = syncService.lastSyncedAt {
                HStack {
                    Text("Last Synced")
                    Spacer()
                    Text(formatDate(lastSync))
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Text("Pending Changes")
                Spacer()
                Text("\(pendingChangesCount)")
                    .foregroundStyle(.secondary)
            }
            
            Button {
                syncNow()
            } label: {
                HStack {
                    Label("Sync Now", systemImage: "arrow.clockwise")
                    Spacer()
                    if isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(isSyncing || !NetworkMonitor.shared.isConnected)
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
    
    // MARK: - Actions
    
    private var pendingChangesCount: Int {
        changeQueueManager.pendingCount
    }
    
    private func syncNow() {
        isSyncing = true
        Task {
            await syncService.syncOnReconnect()
            isSyncing = false
        }
    }
    
    private func logout() {
        authService.logout()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    SettingsView()
}
