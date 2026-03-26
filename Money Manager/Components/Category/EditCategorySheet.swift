import SwiftUI
import SwiftData

struct EditCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel: EditCategoryViewModel
    @State private var iconTapped = false
    @State private var colorTapped = false
    @State private var saveSuccess = false
    
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
                    iconTapped = true
                    viewModel.selectedIcon = icon
                },
                onSelectColor: { color in
                    colorTapped = true
                    viewModel.selectedColor = color
                }
            )
            .sensoryFeedback(.impact(weight: .light), trigger: iconTapped)
            .onChange(of: iconTapped) { _, newValue in
                if newValue { iconTapped = false }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: colorTapped)
            .onChange(of: colorTapped) { _, newValue in
                if newValue { colorTapped = false }
            }
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
                        saveSuccess = true
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.colorWarningMessage)
            }
            .sensoryFeedback(.success, trigger: saveSuccess)
            .onChange(of: saveSuccess) { _, newValue in
                if newValue { saveSuccess = false }
            }
            .task {
                viewModel.modelContext = modelContext
            }
        }
    }
    
    @ViewBuilder
    private var saveButton: some View {
        Button("Save") {
            if viewModel.save() {
                saveSuccess = true
                dismiss()
            }
        }
        .fontWeight(.semibold)
        .disabled(viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}
