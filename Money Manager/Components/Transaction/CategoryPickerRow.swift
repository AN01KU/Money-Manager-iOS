import SwiftUI
import SwiftData

struct CategoryPickerRow: View {
    let category: TransactionCategory
    let selectedCategory: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(category.color)
                    .frame(width: 30)
                Text(category.name)
                Spacer()
                if selectedCategory == category.name {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
        .foregroundStyle(.primary)
        .accessibilityIdentifier(category.name)
    }
}
