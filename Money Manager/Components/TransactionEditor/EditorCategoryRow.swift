import SwiftUI

struct EditorCategoryRow: View {
    @Bindable var viewModel: AddTransactionViewModel
    let customCategories: [Category]

    private var categoryByKey: [String: TransactionCategory] {
        Dictionary(
            uniqueKeysWithValues: TransactionCategory.merge(overrides: customCategories)
                .filter { !$0.isHidden }
                .map { ($0.key, $0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
            Text("Category *")
                .font(AppTypography.subhead)
                .foregroundStyle(AppColors.label2)

            Button {
                viewModel.showCategoryPicker = true
            } label: {
                HStack(spacing: AppConstants.UI.spacingSM) {
                    if let cat = categoryByKey[viewModel.selectedCategory] {
                        AppIcon(name: cat.icon, size: 20, color: cat.color)
                        Text(cat.name)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.label)
                    } else {
                        Text("Select Category")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.primary)
                    }
                    Spacer()
                    AppIcon(name: AppIcons.UI.chevron, size: 14, color: AppColors.primary)
                        .rotationEffect(.degrees(90))
                }
                .padding(AppConstants.UI.spacing12)
                .background(AppColors.primaryBg)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.radius10))
            }
            .tapFeedback()
            .accessibilityIdentifier("category-picker-button")
        }
    }
}
