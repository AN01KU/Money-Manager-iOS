import SwiftUI
import SwiftData

struct RecurringTransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<RecurringTransaction> { !$0.isSoftDeleted }, sort: \RecurringTransaction.name)
    private var recurringTransactions: [RecurringTransaction]

    @State private var viewModel = RecurringTransactionsViewModel()
    @State private var rowTapped = 0
    @State private var deleteTriggered = 0
    @State private var addTriggered = 0

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

                    if !viewModel.activeRecurring.isEmpty {
                        Section("Active") {
                            ForEach(viewModel.activeRecurring) { item in
                                RecurringTransactionRow(recurring: item, onTap: {
                                    rowTapped += 1
                                    viewModel.editingRecurring = item
                                })
                                .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                            }
                            .onDelete { indexSet in
                                deleteTriggered += 1
                                for index in indexSet {
                                    viewModel.deactivate(at: index)
                                }
                            }
                            .sensoryFeedback(.warning, trigger: deleteTriggered)
                        }
                    }

                    if !viewModel.pausedRecurring.isEmpty {
                        Section("Paused") {
                            ForEach(viewModel.pausedRecurring) { item in
                                RecurringTransactionRow(recurring: item, onTap: {
                                    rowTapped += 1
                                    viewModel.editingRecurring = item
                                })
                                .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteTriggered += 1
                                        if let index = viewModel.pausedRecurring.firstIndex(where: { $0.id == item.id }) {
                                            viewModel.delete(at: index)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
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
        .task {
            viewModel.modelContext = modelContext
            viewModel.update(recurring: recurringTransactions)
        }
        .onChange(of: recurringTransactions) { _, newValue in
            viewModel.update(recurring: newValue)
        }
    }
}

#Preview {
    NavigationStack {
        RecurringTransactionsView()
            .modelContainer(for: RecurringTransaction.self)
    }
}
