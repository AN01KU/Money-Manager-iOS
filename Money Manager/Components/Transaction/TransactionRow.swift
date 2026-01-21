//
//  TransactionRow.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct TransactionRow: View {
    let expense: Expense
    
    var category: PredefinedCategory? {
        PredefinedCategory.allCases.first { $0.rawValue == expense.category }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(category: category)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.category)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(expense.expenseDescription ?? "No description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.format(expense.amount))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                if let time = expense.time {
                    Text(formatTime(time))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .contentShape(Rectangle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct CategoryIconView: View {
    let category: PredefinedCategory?
    
    var body: some View {
        ZStack {
            Circle()
                .fill((category?.color ?? Color.gray).opacity(0.2))
                .frame(width: 48, height: 48)
            
            Image(systemName: category?.icon ?? "ellipsis.circle.fill")
                .font(.title3)
                .foregroundColor(category?.color ?? Color.gray)
        }
    }
}

#Preview {
    TransactionRow(
        expense: Expense(
            amount: 450,
            category: "Food & Dining",
            date: Date(),
            time: Date(),
            expenseDescription: "Lunch at cafe"
        )
    )
    .padding()
}
