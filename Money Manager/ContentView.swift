import SwiftUI
import SwiftData

let useTestData: Bool = CommandLine.arguments.contains("useTestData")

struct ContentView: View {
    @ObservedObject private var apiService = APIService.shared
    
    var body: some View {
        if apiService.isAuthenticated || MockData.useDummyData {
            MainTabView()
        } else {
            AuthView()
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Overview()
                .tabItem {
                    Label("Overview", systemImage: "house.fill")
                }
                .tag(0)
            
            GroupsListView()
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }
                .tag(1)
            
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
        apiService.currentUser ?? (MockData.useDummyData ? MockData.currentUser : nil)
    }
    
    var body: some View {
        NavigationStack {
            List {
                profileSection
                financeSection
                preferencesSection
                accountSection
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
    
    // MARK: - Profile
    
    private var profileSection: some View {
        Section {
            if let user = displayUser {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.teal.opacity(0.12))
                            .frame(width: 56, height: 56)
                        
                        Text(String(user.email.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.teal)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(MockData.useDummyData ? MockData.nameForUser(user.id) : user.email.components(separatedBy: "@").first?.capitalized ?? user.email)
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
