import SwiftUI
import SwiftData

struct CategoryPickerRow: View {
    let category: TransactionCategory
    let selectedCategory: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
                if selectedCategory == category.name {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(category.name)
    }
}
