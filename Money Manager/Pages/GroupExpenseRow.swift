//
//  GroupExpenseRow.swift
//  Money Manager
//

import SwiftUI

struct GroupExpenseRow: View {
    let expense: APIGroupExpense
    let members: [APIGroupMember]

    private var amount: Double { Double(expense.total_amount) ?? 0 }

    private var paidByName: String {
        members.first(where: { $0.id == expense.paid_by })?
            .email.components(separatedBy: "@").first?.capitalized ?? "Unknown"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.body)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text("Paid by").foregroundStyle(.secondary)
                    Text(paidByName).foregroundStyle(AppColors.accent)
                }
                .font(.caption)
                Text(expense.created_at, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(CurrencyFormatter.format(amount, showDecimals: true))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}
