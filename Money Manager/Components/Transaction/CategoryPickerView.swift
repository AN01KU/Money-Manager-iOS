import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategory: String
    @Query private var overrides: [CustomCategory]
    @State private var selectionToggled = 0

    private var categories: [TransactionCategory] {
        TransactionCategory.merge(overrides: overrides)
    }

    private var visibleCustom: [TransactionCategory] {
        categories.filter { !$0.isPredefined && !$0.isHidden }
    }

    private var visiblePredefined: [TransactionCategory] {
        categories.filter { $0.isPredefined && !$0.isHidden }
    }

    var body: some View {
        List {
            if !visibleCustom.isEmpty {
                Section("Your Categories") {
                    ForEach(visibleCustom) { category in
                        CategoryPickerRow(category: category, selectedCategory: selectedCategory) {
                            selectionToggled += 1
                            selectedCategory = category.key
                            dismiss()
                        }
                        .sensoryFeedback(.selection, trigger: selectionToggled)
                    }
                }
            }

            Section("Default Categories") {
                ForEach(visiblePredefined) { category in
                    CategoryPickerRow(category: category, selectedCategory: selectedCategory) {
                        selectionToggled += 1
                        selectedCategory = category.key
                        dismiss()
                    }
                    .sensoryFeedback(.selection, trigger: selectionToggled)
                }
            }
        }
        .navigationTitle("Select Category")
        .navigationBarTitleDisplayMode(.inline)
    }
}
