//
//  TransactionRow.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI
import SwiftData

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.timeStyle = .short
    return f
}()

struct TransactionRow: View {
    let expense: Expense
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    init(expense: Expense) {
        self.expense = expense
    }
    
    private var resolved: (icon: String, color: Color) {
        CategoryResolver.resolve(expense.category, customCategories: customCategories)
    }

    private var resolvedIcon: String { resolved.icon }
    private var resolvedColor: Color { resolved.color }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(resolvedColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: resolvedIcon)
                    .font(.title3)
                    .foregroundStyle(resolvedColor)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.category)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(expense.expenseDescription ?? "No description")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let groupName = expense.groupName {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text(groupName)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(AppColors.accent)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.format(expense.amount))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                
                if let time = expense.time {
                    Text(formatTime(time))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(expense.category), \(expense.expenseDescription ?? "No description"), \(CurrencyFormatter.format(expense.amount))")
    }
    
    private func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
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
    .modelContainer(for: [CustomCategory.self], inMemory: true)
}
