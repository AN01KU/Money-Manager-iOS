//
//  GroupBalanceRow.swift
//  Money Manager
//

import SwiftUI

struct GroupBalanceRow: View {
    let balance: APIGroupBalance
    let members: [APIGroupMember]

    private var amount: Double { Double(balance.amount) ?? 0 }
    private var isOwed: Bool { amount < 0 }
    private var isSettled: Bool { amount == 0 }

    private var userName: String {
        members.first(where: { $0.id == balance.user_id })?
            .email.components(separatedBy: "@").first?.capitalized ?? "Unknown"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isSettled ? AppColors.graySubtle : (isOwed ? AppColors.positive.opacity(0.12) : AppColors.expense.opacity(0.12)))
                    .frame(width: 40, height: 40)
                Image(systemName: isSettled ? "checkmark" : (isOwed ? "arrow.down.left" : "arrow.up.right"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSettled ? .secondary : (isOwed ? AppColors.positive : AppColors.expense))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(userName).font(.body).fontWeight(.medium)
                Text(isOwed ? "is owed" : (isSettled ? "settled up" : "owes"))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !isSettled {
                Text(CurrencyFormatter.format(abs(amount), showDecimals: true))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isOwed ? AppColors.positive : AppColors.expense)
            } else {
                Text(CurrencyFormatter.format(0, showDecimals: true))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
