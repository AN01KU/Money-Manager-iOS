import SwiftUI
import SwiftData

struct EditCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: EditCategoryViewModel
    @State private var iconTapped = 0
    @State private var colorTapped = 0
    @State private var saveSuccess = 0

    init(category: TransactionCategory, allCategories: [CustomCategory]) {
        _viewModel = State(wrappedValue: EditCategoryViewModel(
            category: category,
            allCategories: allCategories
        ))
    }

    var body: some View {
        NavigationStack {
            CategoryEditorView(
                name: $viewModel.name,
                selectedIcon: $viewModel.selectedIcon,
                selectedColor: $viewModel.selectedColor,
                colorConflictCategory: viewModel.colorConflictCategory,
                onSelectIcon: { icon in
                    iconTapped += 1
                    viewModel.selectedIcon = icon
                },
                onSelectColor: { color in
                    colorTapped += 1
                    viewModel.selectedColor = color
                }
            )
            .sensoryFeedback(.impact(weight: .light), trigger: iconTapped)
            .sensoryFeedback(.impact(weight: .light), trigger: colorTapped)
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    saveButton
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Duplicate Color", isPresented: $viewModel.showColorWarning) {
                Button("Choose Different", role: .cancel) { }
                Button("Use Anyway") {
                    viewModel.confirmSaveDespiteColorWarning()
                    if viewModel.save() {
                        saveSuccess += 1
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.colorWarningMessage)
            }
            .sensoryFeedback(.success, trigger: saveSuccess)
            .task {
                viewModel.modelContext = modelContext
            }
        }
    }

    @ViewBuilder
    private var saveButton: some View {
        Button("Save") {
            if viewModel.save() {
                saveSuccess += 1
                dismiss()
            }
        }
        .fontWeight(.semibold)
        .disabled(viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}
