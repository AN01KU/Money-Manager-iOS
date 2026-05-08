//
//  ActivityRow.swift
//  Money Manager
//

import SwiftUI

struct ActivityRow: View {
    let item: ActivityItem
    let currentUserId: UUID?

    var body: some View {
        switch item {
        case .transaction(let tx, let groupName):
            TransactionActivityRow(transaction: tx, groupName: groupName)
        case .settlement(let settlement, let groupName):
            SettlementActivityRow(
                settlement: settlement,
                groupName: groupName,
                currentUserId: currentUserId
            )
        }
    }
}

// MARK: - Transaction row

private struct TransactionActivityRow: View {
    let transaction: ActivityTransaction
    let groupName: String

    private var resolved: (icon: String, color: Color) {
        CategoryResolver.resolve(transaction.category, customCategories: [])
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(resolved.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                AppIcon(name: resolved.icon, size: 40 * 0.52, color: resolved.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description ?? transaction.category)
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(groupName)
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                    Text(transaction.date, style: .date)
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(CurrencyFormatter.format(transaction.totalAmount, showDecimals: true))
                .font(AppTypography.amount)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Settlement row

private struct SettlementActivityRow: View {
    let settlement: ActivitySettlement
    let groupName: String
    let currentUserId: UUID?

    private var isCurrentUserPayer: Bool { settlement.fromUserId == currentUserId }

    private var fromName: String {
        settlement.fromUserId == currentUserId ? "You" : settlement.fromName
    }

    private var toName: String {
        settlement.toUserId == currentUserId ? "you" : settlement.toName
    }

    private var accentColor: Color {
        isCurrentUserPayer ? AppColors.expense : AppColors.positive
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                AppIcon(name: AppIcons.UI.settle, size: 40 * 0.52, color: accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(fromName) paid \(toName)")
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(groupName)
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                    Text(settlement.date, style: .date)
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(settlement.amount, showDecimals: true))
                    .font(AppTypography.amount)
                    .foregroundStyle(accentColor)
                Text(isCurrentUserPayer ? "paid" : "received")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
