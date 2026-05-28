import SwiftUI
import SwiftData

struct CategoryPickerRow: View {
    let category: Category
    let selectedCategoryId: UUID
    let action: () -> Void

    var body: some View {
        HStack(spacing: AppConstants.UI.spacing12) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.color).opacity(0.15))
                    .frame(width: AppConstants.UI.iconBadgeSize, height: AppConstants.UI.iconBadgeSize)
                AppIcon(name: category.icon,
                        size: AppConstants.UI.iconBadgeSize * 0.52,
                        color: Color(hex: category.color))
            }
            Text(category.name)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.label)
            Spacer()
            if selectedCategoryId == category.id {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { action() }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(category.name)
    }
}
