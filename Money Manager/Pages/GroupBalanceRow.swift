//
//  GroupBalanceRow.swift
//  Money Manager
//

import SwiftUI

struct GroupBalanceRow: View {
    let debt: PairwiseDebt
    let members: [APIGroupMember]
    let currentUserId: UUID?

    private var isCurrentUserDebtor: Bool { debt.fromUserId == currentUserId }
    private var isCurrentUserCreditor: Bool { debt.toUserId == currentUserId }

    private var fromName: String {
        if isCurrentUserDebtor { return "You" }
        return members.first(where: { $0.id == debt.fromUserId })?.username ?? "Unknown"
    }

    private var toName: String {
        if isCurrentUserCreditor { return "you" }
        return members.first(where: { $0.id == debt.toUserId })?.username ?? "Unknown"
    }

    private var accentColor: Color {
        isCurrentUserCreditor ? AppColors.positive : (isCurrentUserDebtor ? AppColors.expense : .secondary)
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: isCurrentUserDebtor ? "arrow.up.right" : "arrow.down.left")
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(fromName) owes \(toName)")
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            Spacer()
            Text(CurrencyFormatter.format(debt.amount, showDecimals: true))
                .font(AppTypography.amount)
                .foregroundStyle(accentColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct GroupBalanceSettledRow: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColors.graySubtle)
                    .frame(width: 36, height: 36)
                Image(systemName: "checkmark")
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(.secondary)
            }
            Text("All settled up")
                .font(AppTypography.rowPrimary)
                .foregroundStyle(.secondary)
            Spacer()
            Text(CurrencyFormatter.format(0, showDecimals: true))
                .font(AppTypography.amount)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Settlement History Row

private let settlementDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMM dd"
    return f
}()

struct SettlementHistoryRow: View {
    let settlement: APISettlement
    let members: [APIGroupMember]
    let currentUserId: UUID?

    private var fromName: String {
        if settlement.from_user == currentUserId { return "You" }
        return members.first(where: { $0.id == settlement.from_user })?.username ?? "Unknown"
    }

    private var toName: String {
        if settlement.to_user == currentUserId { return "you" }
        return members.first(where: { $0.id == settlement.to_user })?.username ?? "Unknown"
    }

    private var amount: Double { Double(settlement.amount) ?? 0 }

    private var isCurrentUserPayer: Bool { settlement.from_user == currentUserId }
    private var isCurrentUserReceiver: Bool { settlement.to_user == currentUserId }

    private var accentColor: Color {
        if isCurrentUserPayer { return AppColors.expense }
        if isCurrentUserReceiver { return AppColors.positive }
        return .secondary
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: "checkmark.circle")
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(fromName) paid \(toName)")
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(settlementDateFormatter.string(from: settlement.created_at))
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                    if let notes = settlement.notes {
                        Text("·")
                            .font(AppTypography.rowMeta)
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .font(AppTypography.rowMeta)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            Text(CurrencyFormatter.format(amount, showDecimals: true))
                .font(AppTypography.amount)
                .foregroundStyle(accentColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
