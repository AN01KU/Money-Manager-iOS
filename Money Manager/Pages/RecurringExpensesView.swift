import SwiftUI
import SwiftData

struct RecurringExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringExpense.name)
    private var recurringExpenses: [RecurringExpense]
    
    @State private var viewModel = RecurringExpensesViewModel()
    @State private var rowTapped = false
    @State private var deleteTriggered = false
    @State private var addTriggered = false
    
    var body: some View {
        Group {
            if viewModel.allRecurringExpenses.isEmpty {
                EmptyStateView(
                    icon: "arrow.clockwise.circle.fill",
                    title: "No recurring expenses",
                    message: "Add subscriptions and regular bills to track them automatically"
                )
            } else {
                List {
                    if !viewModel.activeExpenses.isEmpty {
                        Section("Active") {
                            ForEach(viewModel.activeExpenses) { expense in
                                RecurringExpenseRow(expense: expense, onTap: {
                                    rowTapped = true
                                    viewModel.editingExpense = expense
                                })
                                .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                                .onChange(of: rowTapped) { _, newValue in
                                    if newValue { rowTapped = false }
                                }
                            }
                            .onDelete { indexSet in
                                deleteTriggered = true
                                for index in indexSet {
                                    viewModel.deactivateExpense(at: index)
                                }
                            }
                            .sensoryFeedback(.warning, trigger: deleteTriggered)
                            .onChange(of: deleteTriggered) { _, newValue in
                                if newValue { deleteTriggered = false }
                            }
                        }
                    }
                    
                    if !viewModel.pausedExpenses.isEmpty {
                        Section("Paused") {
                            ForEach(viewModel.pausedExpenses) { expense in
                                RecurringExpenseRow(expense: expense, onTap: {
                                    rowTapped = true
                                    viewModel.editingExpense = expense
                                })
                                .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
                                .onChange(of: rowTapped) { _, newValue in
                                    if newValue { rowTapped = false }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteTriggered = true
                                        if let index = viewModel.pausedExpenses.firstIndex(where: { $0.id == expense.id }) {
                                            viewModel.deleteExpense(at: index)
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
                .accessibilityLabel("Add recurring expense")
            }
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddRecurringExpenseSheet()
        }
        .sheet(item: $viewModel.editingExpense) { expense in
            EditRecurringExpenseSheet(expense: expense)
        }
        .task {
            viewModel.modelContext = modelContext
            viewModel.update(expenses: recurringExpenses)
        }
        .onChange(of: recurringExpenses) { _, newValue in
            viewModel.update(expenses: newValue)
        }
    }
}

#Preview {
    NavigationStack {
        RecurringExpensesView()
            .modelContainer(for: RecurringExpense.self)
    }
}
