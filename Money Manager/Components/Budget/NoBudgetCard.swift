//
//  NoBudgetCard.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct NoBudgetCard: View {
    let selectedMonth: Date
    let onSetBudget: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: "chart.bar.doc.horizontal",
            title: "No Budget Set",
            message: "Set a monthly budget to track your spending",
            actionTitle: "Set Budget",
            action: onSetBudget
        )
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NoBudgetCard(selectedMonth: Date(), onSetBudget: {})
}
