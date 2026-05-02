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
    @State private var swipedItemID: String?

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
        ScrollView {
            VStack(spacing: AppConstants.UI.spacing20) {
                if !predefinedCategories.isEmpty {
                    CategoryCardSection(header: "DEFAULT CATEGORIES", footer: "Tap to edit icon, color or name. Swipe left to hide.") {
                        ForEach(predefinedCategories) { category in
                            SwipeToDeleteRow(
                                isRevealed: Binding(
                                    get: { swipedItemID == category.id },
                                    set: { swipedItemID = $0 ? category.id : nil }
                                ),
                                onDelete: { viewModel.hideCategory(category) },
                                deleteIcon: "eye.slash",
                                deleteColor: .orange,
                                onTap: { rowTapped += 1; viewModel.categoryToEdit = category }
                            ) {
                                CategoryRow(
                                    category: category,
                                    usageCount: usageCounts[category.name, default: 0],
                                    onTap: {}
                                )
                            }
                            .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                            if category.id != predefinedCategories.last?.id {
                                Divider().padding(.leading, 64)
                            }
                        }
                    }
                }

                if !userCategories.isEmpty {
                    CategoryCardSection(header: "YOUR CATEGORIES") {
                        ForEach(userCategories) { category in
                            SwipeToDeleteRow(
                                isRevealed: Binding(
                                    get: { swipedItemID == category.id },
                                    set: { swipedItemID = $0 ? category.id : nil }
                                ),
                                onDelete: { viewModel.deleteCategory(category) },
                                secondaryAction: SwipeAction(icon: "eye.slash", color: .orange) {
                                    viewModel.hideCategory(category)
                                },
                                onTap: { rowTapped += 1; viewModel.categoryToEdit = category }
                            ) {
                                CategoryRow(
                                    category: category,
                                    usageCount: usageCounts[category.name, default: 0],
                                    onTap: {}
                                )
                            }
                            .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                            if category.id != userCategories.last?.id {
                                Divider().padding(.leading, 64)
                            }
                        }
                    }
                }

                if !hiddenCategories.isEmpty {
                    CategoryCardSection(header: "HIDDEN") {
                        ForEach(hiddenCategories) { category in
                            if category.isPredefined {
                                HiddenCategoryRow(category: category) {
                                    viewModel.restoreCategory(category)
                                }
                            } else {
                                SwipeToDeleteRow(
                                    isRevealed: Binding(
                                        get: { swipedItemID == category.id },
                                        set: { swipedItemID = $0 ? category.id : nil }
                                    ),
                                    onDelete: { viewModel.deleteCategory(category) }
                                ) {
                                    HiddenCategoryRow(category: category) {
                                        viewModel.restoreCategory(category)
                                    }
                                }
                            }
                            if category.id != hiddenCategories.last?.id {
                                Divider().padding(.leading, 64)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppConstants.UI.padding)
            .padding(.top, AppConstants.UI.spacing12)
            .padding(.bottom, AppConstants.UI.spacingXL)
        }
        .background(AppColors.background)
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.large)
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
                    AppIcon(name: AppIcons.UI.more, size: 22, color: AppColors.primary)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: showResetMenu)

                Button {
                    addTriggered += 1
                    viewModel.showAddCategory = true
                } label: {
                    AppIcon(name: AppIcons.UI.add, size: 22, color: AppColors.primary)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: addTriggered)
                .accessibilityLabel("Add category")
                .accessibilityIdentifier("categories.add-button")
            }
        }
        .sheet(isPresented: $viewModel.showAddCategory) {
            AddCategorySheet(allCategories: overrides)
        }
        .sheet(item: $viewModel.categoryToEdit) { category in
            EditCategorySheet(category: category, allCategories: overrides)
        }
        .alert("Delete Category?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { viewModel.categoryToDelete = nil }
            Button("Delete", role: .destructive) { viewModel.confirmDelete() }
        } message: {
            Text("This will permanently remove \"\(viewModel.categoryToDelete?.name ?? "")\". Existing transactions will keep their category name.")
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.deleteConfirmedTrigger)
        .sensoryFeedback(.success, trigger: viewModel.resetTrigger)
        .task { viewModel.modelContext = modelContext }
    }
}

// MARK: - Card section wrapper

private struct CategoryCardSection<Content: View>: View {
    let header: String
    var footer: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
            Text(header)
                .font(AppTypography.footnote)
                .fontWeight(.semibold)
                .tracking(AppTypography.trackingFootnote)
                .foregroundStyle(AppColors.label2)
                .padding(.leading, AppConstants.UI.spacingXS)

            VStack(spacing: 0) {
                content
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))

            if let footer {
                Text(footer)
                    .font(AppTypography.caption1)
                    .foregroundStyle(AppColors.label3)
                    .padding(.leading, AppConstants.UI.spacingXS)
            }
        }
    }
}

// MARK: - Hidden category row

struct HiddenCategoryRow: View {
    let category: TransactionCategory
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: AppConstants.UI.spacing12) {
            ZStack {
                RoundedRectangle(cornerRadius: AppConstants.UI.radius10)
                    .fill(category.color.opacity(0.3))
                    .frame(width: AppConstants.UI.iconBadgeSize, height: AppConstants.UI.iconBadgeSize)
                AppIcon(name: category.icon,
                        size: AppConstants.UI.iconBadgeSize * 0.50,
                        color: category.color.opacity(0.6))
            }

            Text(category.name)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.label2)

            Spacer()

            Button("Restore", action: onRestore)
                .font(AppTypography.subhead)
                .foregroundStyle(AppColors.primary)
        }
        .padding(.horizontal, AppConstants.UI.padding)
        .padding(.vertical, AppConstants.UI.spacing12)
    }
}

#Preview {
    NavigationStack {
        ManageCategoriesView()
    }
    .modelContainer(for: [CustomCategory.self])
}
