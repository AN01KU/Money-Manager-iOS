import SwiftUI
import SwiftData

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    @State private var viewModel = ManageCategoriesViewModel()
    @State private var rowTapped = false
    @State private var deleteTriggered = false
    @State private var hideTriggered = false
    @State private var restoreTriggered = false
    @State private var addTriggered = false
    
    private var predefinedCategories: [CustomCategory] {
        customCategories.filter { $0.isPredefined && !$0.isHidden }
    }
    
    private var userCategories: [CustomCategory] {
        customCategories.filter { !$0.isPredefined && !$0.isHidden }
    }
    
    private var hiddenCategories: [CustomCategory] {
        customCategories.filter { $0.isHidden }
    }
    
    var body: some View {
        List {
            if !predefinedCategories.isEmpty {
                Section {
                    ForEach(predefinedCategories) { category in
                        CategoryRow(category: category, onTap: {
                            rowTapped = true
                            viewModel.categoryToEdit = category
                        })
                        .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                        .onChange(of: rowTapped) { _, newValue in
                            if newValue { rowTapped = false }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if category.isDeletable {
                                Button(role: .destructive) {
                                    deleteTriggered = true
                                    viewModel.deleteCategory(category)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .sensoryFeedback(.warning, trigger: deleteTriggered)
                                .onChange(of: deleteTriggered) { _, newValue in
                                    if newValue { deleteTriggered = false }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Default Categories")
                } footer: {
                    Text("Tap to edit icon, color, or name. Swipe to delete (except Other).")
                }
            }
            
            if !userCategories.isEmpty {
                Section("Your Categories") {
                    ForEach(userCategories) { category in
                        CategoryRow(category: category, onTap: {
                            rowTapped = true
                            viewModel.categoryToEdit = category
                        })
                        .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                        .onChange(of: rowTapped) { _, newValue in
                            if newValue { rowTapped = false }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteTriggered = true
                                viewModel.deleteCategory(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .sensoryFeedback(.warning, trigger: deleteTriggered)
                            .onChange(of: deleteTriggered) { _, newValue in
                                if newValue { deleteTriggered = false }
                            }
                            
                            Button {
                                hideTriggered = true
                                viewModel.hideCategory(category)
                            } label: {
                                Label("Hide", systemImage: "eye.slash")
                            }
                            .tint(.orange)
                            .sensoryFeedback(.impact(weight: .light), trigger: hideTriggered)
                            .onChange(of: hideTriggered) { _, newValue in
                                if newValue { hideTriggered = false }
                            }
                        }
                    }
                }
            }
            
            if !hiddenCategories.isEmpty {
                Section("Hidden Categories") {
                    ForEach(hiddenCategories) { category in
                        HiddenCategoryRow(category: category) {
                            restoreTriggered = true
                            viewModel.restoreCategory(category)
                        }
                        .sensoryFeedback(.success, trigger: restoreTriggered)
                        .onChange(of: restoreTriggered) { _, newValue in
                            if newValue { restoreTriggered = false }
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addTriggered = true
                    viewModel.showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppColors.accent)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: addTriggered)
                .onChange(of: addTriggered) { _, newValue in
                    if newValue { addTriggered = false }
                }
                .accessibilityLabel("Add category")
            }
        }
        .sheet(isPresented: $viewModel.showAddCategory) {
            AddCategorySheet(allCategories: customCategories)
        }
        .sheet(item: $viewModel.categoryToEdit) { category in
            EditCategorySheet(category: category, allCategories: customCategories)
        }
        .alert("Delete Category?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.categoryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.confirmDelete()
            }
        } message: {
            Text("This will permanently remove \"\(viewModel.categoryToDelete?.name ?? "")\". Existing expenses using this category will keep their category name.")
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }
}

struct HiddenCategoryRow: View {
    let category: CustomCategory
    let onRestore: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .foregroundStyle(Color(hex: category.color).opacity(0.5))
                .frame(width: 28)
            
            Text(category.name)
                .font(.body)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Restore") {
                onRestore()
            }
            .font(.caption)
            .foregroundStyle(AppColors.accent)
        }
    }
}

#Preview {
    NavigationStack {
        ManageCategoriesView()
    }
    .modelContainer(for: [CustomCategory.self])
}
