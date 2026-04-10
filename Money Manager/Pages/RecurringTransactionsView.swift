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

    var body: some View {
        Group {
            if viewModel.allRecurring.isEmpty {
                EmptyStateView(
                    icon: "arrow.clockwise.circle.fill",
                    title: "No recurring transactions",
                    message: "Add recurring incomes and expenses to track them automatically"
                )
            } else {
                List {
                    if !viewModel.upcomingThisMonth.isEmpty {
                        Section {
                            ForEach(viewModel.upcomingThisMonth) { item in
                                RecurringTransactionRow(recurring: item, onTap: {
                                    rowTapped += 1
                                    viewModel.editingRecurring = item
                                })
                                .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    deleteButton(for: item)
                                }
                            }
                        } header: {
                            HStack {
                                Text("Upcoming This Month")
                                Spacer()
                                Text(CurrencyFormatter.format(abs(viewModel.upcomingTotalThisMonth)))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(viewModel.upcomingTotalThisMonth >= 0 ? AppColors.income : AppColors.expense)
                            }
                        }
                    }

                    Section("All") {
                        ForEach(viewModel.allRecurring) { item in
                            RecurringTransactionRow(recurring: item, onTap: {
                                rowTapped += 1
                                viewModel.editingRecurring = item
                            })
                            .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                deleteButton(for: item)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Recurring")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    addTriggered += 1
                    viewModel.showAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: addTriggered)
                .accessibilityLabel("Add recurring transaction")
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
                if let item = itemToDelete {
                    viewModel.deleteItem(item)
                }
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

    private func deleteButton(for item: RecurringTransaction) -> some View {
        Button(role: .destructive) {
            itemToDelete = item
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

#Preview {
    NavigationStack {
        RecurringTransactionsView()
            .modelContainer(for: RecurringTransaction.self)
    }
}
