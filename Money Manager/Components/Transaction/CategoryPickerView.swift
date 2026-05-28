import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategoryId: UUID
    @Query private var allCategories: [Category]
    @State private var selectionToggled = 0

    private var visibleCustom: [Category] {
        allCategories.filter { !$0.isPredefined && !$0.isHidden }
    }

    private var visiblePredefined: [Category] {
        allCategories.filter { $0.isPredefined && !$0.isHidden }
    }

    var body: some View {
        List {
            if !visibleCustom.isEmpty {
                Section("Your Categories") {
                    ForEach(visibleCustom) { category in
                        CategoryPickerRow(category: category, selectedCategoryId: selectedCategoryId) {
                            selectionToggled += 1
                            selectedCategoryId = category.id
                            dismiss()
                        }
                        .sensoryFeedback(.selection, trigger: selectionToggled)
                    }
                }
            }

            Section("Default Categories") {
                ForEach(visiblePredefined) { category in
                    CategoryPickerRow(category: category, selectedCategoryId: selectedCategoryId) {
                        selectionToggled += 1
                        selectedCategoryId = category.id
                        dismiss()
                    }
                    .sensoryFeedback(.selection, trigger: selectionToggled)
                    .accessibilityIdentifier("category-picker.\(category.key)")
                }
            }
        }
        .navigationTitle("Select Category")
        .navigationBarTitleDisplayMode(.inline)
    }
}
