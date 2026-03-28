import SwiftUI
import SwiftData

struct RecurringTransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringTransaction.name)
    private var recurringTransactions: [RecurringTransaction]

    @State private var viewModel = RecurringTransactionsViewModel()
    @State private var rowTapped = false
    @State private var deleteTriggered = false
    @State private var addTriggered = false

    var body: some View {
        Group {
            if viewModel.allRecurring.isEmpty {
                EmptyStateView(
                    icon: "arrow.clockwise.circle.fill",
                    title: "No recurring transactions",
                    message: "Add subscriptions and regular bills to track them automatically"
                )
            } else {
                List {
                    if !viewModel.activeRecurring.isEmpty {
                        Section("Active") {
                            ForEach(viewModel.activeRecurring) { item in
                                RecurringTransactionRow(recurring: item, onTap: {
                                    rowTapped = true
                                    viewModel.editingRecurring = item
                                })
                                .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                                .onChange(of: rowTapped) { _, newValue in
                                    if newValue { rowTapped = false }
                                }
                            }
                            .onDelete { indexSet in
                                deleteTriggered = true
                                for index in indexSet {
                                    viewModel.deactivate(at: index)
                                }
                            }
                            .sensoryFeedback(.warning, trigger: deleteTriggered)
                            .onChange(of: deleteTriggered) { _, newValue in
                                if newValue { deleteTriggered = false }
                            }
                        }
                    }

                    if !viewModel.pausedRecurring.isEmpty {
                        Section("Paused") {
                            ForEach(viewModel.pausedRecurring) { item in
                                RecurringTransactionRow(recurring: item, onTap: {
                                    rowTapped = true
                                    viewModel.editingRecurring = item
                                })
                                .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                                .onChange(of: rowTapped) { _, newValue in
                                    if newValue { rowTapped = false }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteTriggered = true
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
                    addTriggered = true
                    viewModel.showAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: addTriggered)
                .onChange(of: addTriggered) { _, newValue in
                    if newValue { addTriggered = false }
                }
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
