import SwiftUI

struct GroupTransactionRow: View {
    let transaction: APIGroupTransaction
    let members: [APIGroupMember]
    var currentUserId: UUID? = nil

    private var amount: Double { Double(transaction.totalAmount) ?? 0 }
    private var isCurrentUserPayer: Bool { transaction.paidByUserId == currentUserId }
    private var isCurrentUserInvolved: Bool {
        isCurrentUserPayer || transaction.splits.contains { $0.userId == currentUserId }
    }

    private var paidByName: String {
        members.first(where: { $0.id == transaction.paidByUserId })?.username ?? "Unknown"
    }

    private var resolved: (icon: String, color: Color) {
        CategoryResolver.resolve(transaction.category, customCategories: [])
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(resolved.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: resolved.icon)
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(resolved.color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description ?? transaction.category)
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 3) {
                    Image(systemName: "person.fill")
                        .font(AppTypography.rowMeta)
                    Text(paidByName)
                        .font(AppTypography.rowMeta)
                }
                .foregroundStyle(isCurrentUserPayer ? AppColors.accent : .secondary)
            }

            Spacer()

            Text(CurrencyFormatter.format(amount, showDecimals: true))
                .font(AppTypography.amount)
                .foregroundStyle(isCurrentUserInvolved ? .primary : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
