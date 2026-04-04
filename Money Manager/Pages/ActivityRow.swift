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
        case .settlement(let settlement, let groupName, let memberMap):
            SettlementActivityRow(
                settlement: settlement,
                groupName: groupName,
                memberMap: memberMap,
                currentUserId: currentUserId
            )
        }
    }
}

// MARK: - Transaction row

private struct TransactionActivityRow: View {
    let transaction: APIGroupTransaction
    let groupName: String

    private var amount: Double { transaction.totalAmount }

    private var resolved: (icon: String, color: Color) {
        CategoryResolver.resolve(transaction.category, customCategories: [])
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(resolved.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: resolved.icon)
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(resolved.color)
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

            Text(CurrencyFormatter.format(amount, showDecimals: true))
                .font(AppTypography.amount)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Settlement row

private struct SettlementActivityRow: View {
    let settlement: APISettlement
    let groupName: String
    let memberMap: [UUID: String]
    let currentUserId: UUID?

    private var isCurrentUserPayer: Bool { settlement.fromUser == currentUserId }
    private var amount: Double { settlement.amount }

    private var fromName: String {
        if settlement.fromUser == currentUserId { return "You" }
        return memberMap[settlement.fromUser] ?? "Unknown"
    }

    private var toName: String {
        if settlement.toUser == currentUserId { return "you" }
        return memberMap[settlement.toUser] ?? "Unknown"
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
                Image(systemName: "arrow.left.arrow.right")
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(accentColor)
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
                    Text(settlement.createdAt, style: .date)
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(amount, showDecimals: true))
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
