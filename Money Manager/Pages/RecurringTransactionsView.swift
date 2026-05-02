import SwiftUI
import SwiftData

struct RecurringTransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<RecurringTransaction> { !$0.isSoftDeleted }, sort: \RecurringTransaction.name)
    private var recurringTransactions: [RecurringTransaction]

    @State private var viewModel = RecurringTransactionsViewModel()
    @State private var rowTapped = 0
    @State private var addTriggered = 0
    @State private var itemToDelete: RecurringTransaction?
    @State private var swipedItemID: UUID?

    var body: some View {
        Group {
            if viewModel.allRecurring.isEmpty {
                EmptyStateView(
                    icon: "arrow.clockwise.circle.fill",
                    title: "No recurring transactions",
                    message: "Add recurring incomes and expenses to track them automatically"
                )
            } else {
                ScrollView {
                    VStack(spacing: AppConstants.UI.spacing20) {
                        if !viewModel.upcomingThisMonth.isEmpty {
                            recurringSection(
                                header: "UPCOMING THIS MONTH",
                                items: viewModel.upcomingThisMonth,
                                totalAmount: viewModel.upcomingTotalThisMonth
                            )
                        }
                        recurringSection(header: "ALL", items: viewModel.allRecurring, totalAmount: nil)
                    }
                    .padding(.horizontal, AppConstants.UI.padding)
                    .padding(.top, AppConstants.UI.spacing12)
                    .padding(.bottom, AppConstants.UI.spacingXL)
                }
                .background(AppColors.background)
            }
        }
        .navigationTitle("Recurring")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addTriggered += 1
                    viewModel.showAddSheet = true
                } label: {
                    AppIcon(name: AppIcons.UI.add, size: 22, color: AppColors.primary)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: addTriggered)
                .accessibilityLabel("Add recurring transaction")
                .accessibilityIdentifier("recurring.add-button")
            }
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddRecurringTransactionSheet()
        }
        .sheet(item: $viewModel.editingRecurring) { item in
            EditRecurringTransactionSheet(recurring: item)
        }
        .alert("Delete Recurring?", isPresented: Binding(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { itemToDelete = nil }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete { viewModel.deleteItem(item) }
                itemToDelete = nil
            }
        } message: {
            Text("This will permanently delete \"\(itemToDelete?.name ?? "")\". Future transactions will no longer be generated.")
        }
        .task {
            viewModel.modelContext = modelContext
            viewModel.update(recurring: recurringTransactions)
        }
        .onChange(of: recurringTransactions) { _, newValue in
            viewModel.update(recurring: newValue)
        }
    }

    @ViewBuilder
    private func recurringSection(header: String, items: [RecurringTransaction], totalAmount: Double?) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
            HStack {
                Text(header)
                    .font(AppTypography.footnote)
                    .fontWeight(.semibold)
                    .tracking(AppTypography.trackingFootnote)
                    .foregroundStyle(AppColors.label2)

                if let total = totalAmount {
                    Spacer()
                    Text(CurrencyFormatter.format(abs(total)))
                        .font(AppTypography.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(total >= 0 ? AppColors.income : AppColors.expense)
                }
            }
            .padding(.leading, AppConstants.UI.spacingXS)

            VStack(spacing: 0) {
                ForEach(items) { item in
                    SwipeToDeleteRow(
                        isRevealed: Binding(
                            get: { swipedItemID == item.id },
                            set: { revealed in swipedItemID = revealed ? item.id : nil }
                        ),
                        onDelete: { itemToDelete = item }
                    ) {
                        RecurringTransactionRow(
                            recurring: item,
                            onTap: {
                                rowTapped += 1
                                viewModel.editingRecurring = item
                            },
                            onToggle: { viewModel.toggle(item) }
                        )
                        .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                    }

                    if item.id != items.last?.id {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        }
    }
}


#Preview {
    NavigationStack {
        RecurringTransactionsView()
            .modelContainer(for: RecurringTransaction.self)
    }
}
