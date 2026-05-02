import SwiftUI
import SwiftData

struct RecurringTransactionRow: View {
    let recurring: RecurringTransaction
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    let onTap: () -> Void
    let onToggle: () -> Void

    var body: some View {
        if recurring.modelContext == nil {
            EmptyView()
        } else {
            let lookup = CategoryResolver.makeLookup(from: customCategories)
            let (categoryIcon, categoryColor) = CategoryResolver.resolve(recurring.category, lookup: lookup)
            Button(action: onTap) {
                HStack(spacing: AppConstants.UI.spacing12) {
                    ZStack {
                        Circle()
                            .fill(categoryColor.opacity(recurring.isActive ? 0.15 : 0.08))
                            .frame(width: AppConstants.UI.iconBadgeSize, height: AppConstants.UI.iconBadgeSize)
                        AppIcon(name: categoryIcon,
                                size: AppConstants.UI.iconBadgeSize * 0.52,
                                color: categoryColor.opacity(recurring.isActive ? 1 : 0.4))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(recurring.name)
                            .font(AppTypography.body)
                            .foregroundStyle(recurring.isActive ? AppColors.label : AppColors.label2)

                        HStack(spacing: AppConstants.UI.spacingXS) {
                            Text(recurring.frequency.rawValue.capitalized)
                                .font(AppTypography.caption1)
                                .foregroundStyle(AppColors.label2)
                                .padding(.horizontal, AppConstants.UI.spacingSM)
                                .padding(.vertical, 3)
                                .background(AppColors.surface2)
                                .clipShape(Capsule())

                            if !recurring.isActive {
                                Text("Paused")
                                    .font(AppTypography.caption1)
                                    .foregroundStyle(AppColors.warning)
                                    .padding(.horizontal, AppConstants.UI.spacingSM)
                                    .padding(.vertical, 3)
                                    .background(AppColors.warning.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Spacer()

                    HStack(spacing: AppConstants.UI.spacing12) {
                        Text(CurrencyFormatter.format(recurring.amount))
                            .font(AppTypography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                recurring.isActive
                                    ? (recurring.type == .income ? AppColors.income : AppColors.expense)
                                    : AppColors.label3
                            )

                        Toggle("", isOn: Binding(
                            get: { recurring.isActive },
                            set: { _ in onToggle() }
                        ))
                        .labelsHidden()
                        .tint(AppColors.accent)
                        .accessibilityRemoveTraits(.isButton)
                    }
                }
                .padding(.horizontal, AppConstants.UI.padding)
                .padding(.vertical, AppConstants.UI.spacing12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(recurring.name), \(CurrencyFormatter.format(recurring.amount)), \(recurring.isActive ? "Active" : "Paused")")
            .accessibilityIdentifier("recurring.row")
        }
    }
}
