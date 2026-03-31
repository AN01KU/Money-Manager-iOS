import SwiftUI
import SwiftData

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.timeStyle = .short
    return f
}()

struct TransactionRow: View {
    let transaction: Transaction
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    init(transaction: Transaction) {
        self.transaction = transaction
    }

    private var resolved: (icon: String, color: Color) {
        CategoryResolver.resolve(transaction.category, customCategories: customCategories)
    }

    private var resolvedIcon: String { resolved.icon }
    private var resolvedColor: Color { resolved.color }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(resolvedColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: resolvedIcon)
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(resolvedColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.transactionDescription ?? transaction.category)
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if transaction.settlementId != nil, let groupName = transaction.groupName {
                    SettlementBadge(groupName: groupName)
                } else if transaction.groupTransactionId != nil, let groupID = transaction.groupId {
                    GroupBadge(
                        groupName: transaction.groupName ?? "Group",
                        groupID: groupID
                    )
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text((transaction.type == .income ? "+" : "-") + CurrencyFormatter.format(transaction.amount))
                    .font(AppTypography.amount)
                    .foregroundStyle(transaction.type == .income ? AppColors.positive : AppColors.expense)

                if let time = transaction.time {
                    Text(formatTime(time))
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.transactionDescription ?? transaction.category), \(transaction.category), \(CurrencyFormatter.format(transaction.amount))")
    }

    private func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}

// MARK: - Settlement Badge

private struct SettlementBadge: View {
    @Environment(\.authService) private var authService
    let groupName: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "arrow.left.arrow.right")
                .font(AppTypography.rowMeta)
            Text(groupName)
                .font(AppTypography.rowMeta)
            Image(systemName: authService.isAuthenticated ? "chevron.right" : "lock.fill")
                .font(AppTypography.badgeIcon)
        }
        .foregroundStyle(authService.isAuthenticated ? AppColors.warning : .secondary)
    }
}

// MARK: - Group Badge

private struct GroupBadge: View {
    @Environment(\.authService) private var authService
    let groupName: String
    let groupID: UUID

    var body: some View {
        Button {
            guard authService.isAuthenticated else { return }
            NotificationCenter.default.post(
                name: .appRouteReceived,
                object: AppRoute.group(groupID)
            )
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "person.2.fill")
                    .font(AppTypography.rowMeta)
                Text(groupName)
                    .font(AppTypography.rowMeta)
                Image(systemName: authService.isAuthenticated ? "chevron.right" : "lock.fill")
                    .font(AppTypography.badgeIcon)
            }
            .foregroundStyle(authService.isAuthenticated ? AppColors.accent : .secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TransactionRow(
        transaction: Transaction(
            amount: 450,
            category: "Food & Dining",
            date: Date(),
            time: Date(),
            transactionDescription: "Lunch at cafe"
        )
    )
    .padding()
    .modelContainer(for: [CustomCategory.self], inMemory: true)
}
