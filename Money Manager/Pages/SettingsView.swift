import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedCurrency") private var selectedCurrency = "INR"
    
    var body: some View {
        NavigationStack {
            List {
                financeSection
                preferencesSection
                aboutSection
            }
            .navigationTitle("Settings")
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
}

#Preview {
    SettingsView()
}
