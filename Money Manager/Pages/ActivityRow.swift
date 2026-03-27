//
//  ActivityRow.swift
//  Money Manager
//

import SwiftUI

struct ActivityRow: View {
    let expense: APIGroupTransaction
    let groupName: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.accentSubtle)
                    .frame(width: 48, height: 48)
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description ?? "Expense")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(groupName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(Double(expense.total_amount) ?? 0, showDecimals: true))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.expense)
                Text(expense.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}
