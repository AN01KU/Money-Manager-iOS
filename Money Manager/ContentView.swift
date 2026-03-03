import SwiftUI
import SwiftData

let useTestData: Bool = CommandLine.arguments.contains("useTestData")

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

struct MainTabView: View {
    @ObservedObject private var apiService = APIService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Overview()
                .tabItem {
                    Label("Overview", systemImage: "house.fill")
                }
                .tag(0)
            
            if apiService.isAuthenticated || useTestData {
                GroupsListView()
                    .tabItem {
                        Label("Groups", systemImage: "person.3.fill")
                    }
                    .tag(1)
            }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .accentColor(.teal)
    }
}

struct SettingsView: View {
    @ObservedObject private var apiService = APIService.shared
    @AppStorage("selectedCurrency") private var selectedCurrency = "INR"
    @State private var showLogoutConfirmation = false
    
    private var displayUser: APIUser? {
        apiService.currentUser ?? (useTestData ? TestData.currentUser : nil)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if apiService.isAuthenticated {
                    profileSection
                    syncSection
                } else {
                    loginPromptSection
                }
                financeSection
                preferencesSection
                if apiService.isAuthenticated {
                    accountSection
                }
                aboutSection
            }
            .navigationTitle("Settings")
            .confirmationDialog("Log Out", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) {
                    apiService.logout()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
    
    @State private var showLoginSheet = false
    
    // MARK: - Login Prompt
    
    private var loginPromptSection: some View {
        Section {
            Button {
                showLoginSheet = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.teal.opacity(0.12))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.title2)
                            .foregroundColor(.teal)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sign in to sync")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Back up data & access group splits")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            AuthView()
        }
    }
    
    // MARK: - Profile
    
    private var profileSection: some View {
        Section {
            if let user = displayUser {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.teal.opacity(0.12))
                            .frame(width: 56, height: 56)
                        
                        Text(String(user.username.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.teal)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(useTestData ? TestData.nameForUser(user.id) : user.username)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Sync Status
    
    @ObservedObject private var syncService = SyncService.shared
    
    private var syncSection: some View {
        Section("Sync") {
            HStack {
                Image(systemName: syncService.isConnected ? "wifi" : "wifi.slash")
                    .foregroundColor(syncService.isConnected ? .green : .red)
                Text(syncService.isConnected ? "Online" : "Offline")
                    .foregroundColor(syncService.isConnected ? .primary : .secondary)
                Spacer()
                if syncService.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if syncService.pendingCount > 0 {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.orange)
                    Text("\(syncService.pendingCount) pending")
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
            
            if syncService.failedCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("\(syncService.failedCount) failed")
                        .foregroundColor(.red)
                    Spacer()
                    Button("Clear") {
                        syncService.clearFailedItems()
                    }
                    .font(.subheadline)
                }
            }
            
            if let lastSync = syncService.lastSyncDate {
                HStack {
                    Text("Last synced")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(lastSync, style: .relative)
                        .foregroundColor(.secondary)
                }
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
                        .foregroundColor(.secondary)
                }
            }
            
            NavigationLink {
                ExportDataView()
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
        }
    }
    
    // MARK: - Account
    
    private var accountSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Log Out")
                }
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
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ExportDataView: View {
    var body: some View {
        EmptyStateView(
            icon: "square.and.arrow.up",
            title: "Export Coming Soon",
            message: "Export your expenses and budgets as CSV or PDF"
        )
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, MonthlyBudget.self, CustomCategory.self])
}
