import SwiftUI

struct EditorCategoryRow: View {
    @Bindable var viewModel: TransactionEditorViewModel

    private var selectedCategory: Category? {
        viewModel.customCategories.first { $0.id == viewModel.selectedCategoryId }
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
                    if let cat = selectedCategory {
                        AppIcon(name: cat.icon, size: 20, color: Color(hex: cat.color))
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
