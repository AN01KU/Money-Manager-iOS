//
//  BudgetOverviewCard.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct BudgetOverviewCard: View {
    let budget: MonthlyBudget
    let spent: Double
    
    private var percentage: Int {
        guard budget.limit > 0 else { return 0 }
        return Int((spent / budget.limit) * 100.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(CurrencyFormatter.format(spent))
                    .font(.title2)
                    .fontWeight(.bold)
                Text("/ \(CurrencyFormatter.format(budget.limit))")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text("Budget")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                BudgetProgressBar(percentage: percentage)
                
                Text("\(percentage)%")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    BudgetOverviewCard(
        budget: MonthlyBudget(year: 2025, month: 1, limit: 50000),
        spent: 32450
    )
    .padding()
}
