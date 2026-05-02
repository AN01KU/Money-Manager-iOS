import SwiftUI
import SwiftData

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.timeStyle = .short
    return f
}()

struct TransactionRow: View {
    let transaction: Transaction
    let categoryLookup: [String: CustomCategory]
    var onGroupTapped: ((UUID) -> Void)?

    private var resolved: (name: String, icon: String, color: Color) {
        CategoryResolver.resolveAll(transaction.category, lookup: categoryLookup)
    }

    private var resolvedIcon: String { resolved.icon }
    private var resolvedColor: Color { resolved.color }
    private var resolvedName: String { resolved.name }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(resolvedColor.opacity(0.15))
                    .frame(width: AppConstants.UI.iconBadgeSize, height: AppConstants.UI.iconBadgeSize)

                AppIcon(name: resolvedIcon,
                        size: AppConstants.UI.iconBadgeSize * 0.52,
                        color: resolvedColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.transactionDescription ?? resolvedName)
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if transaction.settlementId != nil, let groupName = transaction.groupName {
                    SettlementBadge(groupName: groupName)
                } else if transaction.groupTransactionId != nil, let groupID = transaction.groupId {
                    GroupBadge(
                        groupName: transaction.groupName ?? "Group",
                        groupID: groupID,
                        onGroupTapped: onGroupTapped
                    )
                } else if transaction.recurringExpenseId != nil {
                    RecurringBadge()
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
        .accessibilityLabel("\(transaction.transactionDescription ?? resolvedName), \(resolvedName), \(CurrencyFormatter.format(transaction.amount))")
        .accessibilityIdentifier("transaction.row")
    }

    private func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}

// MARK: - Recurring Badge

private struct RecurringBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            AppIcon(name: AppIcons.UI.recurring, size: 11, color: AppColors.accent)
            Text("Recurring")
                .font(AppTypography.rowMeta)
                .foregroundStyle(AppColors.accent)
        }
    }
}

// MARK: - Settlement Badge

private struct SettlementBadge: View {
    @Environment(\.authService) private var authService
    let groupName: String

    var body: some View {
        let color: Color = authService.isAuthenticated ? AppColors.warning : AppColors.label2
        HStack(spacing: 4) {
            AppIcon(name: AppIcons.UI.settle, size: 11, color: color)
            Text(groupName)
                .font(AppTypography.rowMeta)
                .foregroundStyle(color)
            AppIcon(name: authService.isAuthenticated ? AppIcons.UI.chevron : AppIcons.UI.close, size: 10, color: color)
        }
    }
}

// MARK: - Group Badge

private struct GroupBadge: View {
    @Environment(\.authService) private var authService
    let groupName: String
    let groupID: UUID
    var onGroupTapped: ((UUID) -> Void)?

    var body: some View {
        let color: Color = authService.isAuthenticated ? AppColors.accent : AppColors.label2
        Button {
            guard authService.isAuthenticated else { return }
            onGroupTapped?(groupID)
        } label: {
            HStack(spacing: 4) {
                AppIcon(name: AppIcons.UI.groups, size: 11, color: color)
                Text(groupName)
                    .font(AppTypography.rowMeta)
                    .foregroundStyle(color)
                AppIcon(name: authService.isAuthenticated ? AppIcons.UI.chevron : AppIcons.UI.close, size: 10, color: color)
            }
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
        ),
        categoryLookup: [:]
    )
    .padding()
}
