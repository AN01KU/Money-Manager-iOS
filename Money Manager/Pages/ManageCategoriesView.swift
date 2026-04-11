import SwiftUI
import SwiftData

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var overrides: [CustomCategory]
    @Query(filter: #Predicate<Transaction> { !$0.isSoftDeleted }) private var allTransactions: [Transaction]

    @State private var viewModel = ManageCategoriesViewModel()
    @State private var rowTapped = 0
    @State private var addTriggered = 0
    @State private var showResetMenu = 0

    private var allCategories: [TransactionCategory] {
        TransactionCategory.merge(overrides: overrides)
    }

    private var predefinedCategories: [TransactionCategory] {
        allCategories.filter { $0.isPredefined && !$0.isHidden }
    }

    private var userCategories: [TransactionCategory] {
        allCategories.filter { !$0.isPredefined && !$0.isHidden }
    }

    private var hiddenCategories: [TransactionCategory] {
        allCategories.filter { $0.isHidden }
    }

    private var usageCounts: [String: Int] {
        Dictionary(grouping: allTransactions, by: \.category).mapValues(\.count)
    }

    var body: some View {
        List {
            if !predefinedCategories.isEmpty {
                Section {
                    ForEach(predefinedCategories) { category in
                        CategoryRow(category: category, usageCount: usageCounts[category.name, default: 0], onTap: {
                            rowTapped += 1
                            viewModel.categoryToEdit = category
                        })
                        .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                viewModel.hideCategory(category)
                            } label: {
                                Label("Hide", systemImage: "eye.slash")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    Text("Default Categories")
                } footer: {
                    Text("Tap to edit icon, color, or name. Swipe left to hide.")
                }
            }

            if !userCategories.isEmpty {
                Section("Your Categories") {
                    ForEach(userCategories) { category in
                        CategoryRow(category: category, usageCount: usageCounts[category.name, default: 0], onTap: {
                            rowTapped += 1
                            viewModel.categoryToEdit = category
                        })
                        .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteCategory(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                viewModel.hideCategory(category)
                            } label: {
                                Label("Hide", systemImage: "eye.slash")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }

            if !hiddenCategories.isEmpty {
                Section("Hidden") {
                    ForEach(hiddenCategories) { category in
                        HiddenCategoryRow(category: category) {
                            viewModel.restoreCategory(category)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !category.isPredefined {
                                Button(role: .destructive) {
                                    viewModel.deleteCategory(category)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showResetMenu += 1
                        viewModel.restoreDefaults(modelContext: modelContext)
                    } label: {
                        Label("Restore Defaults", systemImage: "arrow.counterclockwise")
                    }

                    Button(role: .destructive) {
                        showResetMenu += 1
                        viewModel.resetAll(modelContext: modelContext)
                    } label: {
                        Label("Reset All Categories", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: showResetMenu)

                Button {
                    addTriggered += 1
                    viewModel.showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppColors.accent)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: addTriggered)
                .accessibilityLabel("Add category")
            }
        }
        .sheet(isPresented: $viewModel.showAddCategory) {
            AddCategorySheet(allCategories: overrides)
        }
        .sheet(item: $viewModel.categoryToEdit) { category in
            EditCategorySheet(category: category, allCategories: overrides)
        }
        .alert("Delete Category?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.categoryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.confirmDelete()
            }
        } message: {
            Text("This will permanently remove \"\(viewModel.categoryToDelete?.name ?? "")\". Existing transactions using this category will keep their category name.")
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.deleteConfirmedTrigger)
        .sensoryFeedback(.success, trigger: viewModel.resetTrigger)
        .task {
            viewModel.modelContext = modelContext
        }
    }
}

struct HiddenCategoryRow: View {
    let category: TransactionCategory
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .foregroundStyle(category.color.opacity(0.5))
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
