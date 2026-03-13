import SwiftUI
import SwiftData

struct EditCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel: EditCategoryViewModel
    
    init(category: CustomCategory, allCategories: [CustomCategory]) {
        _viewModel = State(wrappedValue: EditCategoryViewModel(category: category, allCategories: allCategories))
    }
    
    var body: some View {
        NavigationStack {
            CategoryEditorView(
                name: $viewModel.name,
                selectedIcon: $viewModel.selectedIcon,
                selectedColor: $viewModel.selectedColor,
                colorConflictCategory: viewModel.colorConflictCategory,
                onSelectIcon: { icon in
                    HapticManager.impact(.light)
                    viewModel.selectedIcon = icon
                },
                onSelectColor: { color in
                    HapticManager.impact(.light)
                    viewModel.selectedColor = color
                }
            )
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
                        HapticManager.notification(.success)
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.colorWarningMessage)
            }
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
        }
    }
    
    @ViewBuilder
    private var saveButton: some View {
        Button("Save") {
            if viewModel.save() {
                HapticManager.notification(.success)
                dismiss()
            }
        }
        .fontWeight(.semibold)
        .disabled(viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}
