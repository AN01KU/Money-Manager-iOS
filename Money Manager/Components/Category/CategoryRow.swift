import SwiftUI

struct CategoryRow: View {
    let category: TransactionCategory
    var usageCount: Int = 0
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppConstants.UI.spacing12) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.15))
                        .frame(width: AppConstants.UI.iconBadgeSize, height: AppConstants.UI.iconBadgeSize)
                    AppIcon(name: category.icon,
                            size: AppConstants.UI.iconBadgeSize * 0.52,
                            color: category.color)
                }

                Text(category.name)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.label)

                Spacer()

                if usageCount > 0 {
                    Text("\(usageCount)")
                        .font(AppTypography.caption1)
                        .foregroundStyle(AppColors.label2)
                        .padding(.horizontal, AppConstants.UI.spacingSM)
                        .padding(.vertical, 3)
                        .background(AppColors.surface2)
                        .clipShape(Circle())
                }

                if category.isPredefined {
                    Text("Default")
                        .font(AppTypography.caption1)
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, AppConstants.UI.spacingSM)
                        .padding(.vertical, 3)
                        .background(AppColors.primaryBg)
                        .clipShape(Capsule())
                }

                AppIcon(name: AppIcons.UI.chevron, size: 16, color: AppColors.label3)
            }
            .padding(.horizontal, AppConstants.UI.padding)
            .padding(.vertical, AppConstants.UI.spacing12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.name), \(usageCount) transactions, \(category.isPredefined ? "Default category" : "Custom category")")
        .accessibilityIdentifier("category.row")
    }
}
