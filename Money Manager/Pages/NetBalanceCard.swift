//
//  NetBalanceCard.swift
//  Money Manager
//

import SwiftUI

struct NetBalanceCard: View {
    let netBalance: Double
    let groupCount: Int

    private var isOwed: Bool { netBalance > 0 }
    private var isSettled: Bool { netBalance == 0 }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Net Balance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(abs(netBalance), showDecimals: true))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(isSettled ? .primary : (isOwed ? AppColors.positive : AppColors.expense))
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(isSettled ? AppColors.graySubtle : (isOwed ? AppColors.positive.opacity(0.12) : AppColors.expense.opacity(0.12)))
                        .frame(width: 48, height: 48)
                    Image(systemName: isSettled ? "checkmark" : (isOwed ? "arrow.down.left" : "arrow.up.right"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSettled ? .secondary : (isOwed ? AppColors.positive : AppColors.expense))
                }
            }
            HStack {
                Text(isSettled ? "All settled up" : (isOwed ? "You are owed overall" : "You owe overall"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(groupCount) group\(groupCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
}
