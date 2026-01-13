//
//  SpendingSummaryCard.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct SpendingSummaryCard: View {
    let totalSpent: Double
    let transactionCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Spent")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(CurrencyFormatter.format(totalSpent))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Transactions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(transactionCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    SpendingSummaryCard(totalSpent: 32450, transactionCount: 42)
        .padding()
}
