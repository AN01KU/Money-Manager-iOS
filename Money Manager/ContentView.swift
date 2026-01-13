//
//  ContentView.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 25/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Overview()
                .tabItem {
                    Label("Overview", systemImage: "house.fill")
                }
                .tag(0)
            
            BudgetsView()
                .tabItem {
                    Label("Budgets", systemImage: "chart.bar.fill")
                }
                .tag(1)
        }
        .accentColor(.teal)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, MonthlyBudget.self])
}
