import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategory: String
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    @State private var selectionToggled = false
    
    private var visiblePredefined: [CustomCategory] {
        customCategories.filter { $0.isPredefined && !$0.isHidden }
    }
    
    private var visibleCustom: [CustomCategory] {
        customCategories.filter { !$0.isPredefined && !$0.isHidden }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !visibleCustom.isEmpty {
                    Section("Your Categories") {
                        ForEach(visibleCustom) { category in
                            CategoryPickerRow(category: category, selectedCategory: selectedCategory) {
                                selectionToggled = true
                                selectedCategory = category.name
                                dismiss()
                            }
                            .sensoryFeedback(.selection, trigger: selectionToggled)
                            .onChange(of: selectionToggled) { _, newValue in
                                if newValue { selectionToggled = false }
                            }
                        }
                    }
                }
                
                Section("Default Categories") {
                    ForEach(visiblePredefined) { category in
                        CategoryPickerRow(category: category, selectedCategory: selectedCategory) {
                            selectionToggled = true
                            selectedCategory = category.name
                            dismiss()
                        }
                        .sensoryFeedback(.selection, trigger: selectionToggled)
                        .onChange(of: selectionToggled) { _, newValue in
                            if newValue { selectionToggled = false }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
