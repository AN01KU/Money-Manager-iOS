import SwiftUI
import SwiftData

struct RecurringExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringExpense.name)
    private var recurringExpenses: [RecurringExpense]
    
    @State private var viewModel = RecurringExpensesViewModel()
    
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
                                    HapticManager.impact(.light)
                                    viewModel.editingExpense = expense
                                })
                            }
                            .onDelete { indexSet in
                                HapticManager.notification(.warning)
                                for index in indexSet {
                                    viewModel.deactivateExpense(at: index)
                                }
                            }
                        }
                    }
                    
                    if !viewModel.pausedExpenses.isEmpty {
                        Section("Paused") {
                            ForEach(viewModel.pausedExpenses) { expense in
                                RecurringExpenseRow(expense: expense, onTap: {
                                    HapticManager.impact(.light)
                                    viewModel.editingExpense = expense
                                })
                            }
                            .onDelete { indexSet in
                                HapticManager.notification(.warning)
                                for index in indexSet {
                                    viewModel.deactivateExpense(at: index + viewModel.activeExpenses.count)
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
                    HapticManager.impact(.medium)
                    viewModel.showAddSheet = true
                }) {
                    Image(systemName: "plus")
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
        .onAppear {
            viewModel.configure(expenses: recurringExpenses, modelContext: modelContext)
        }
        .onChange(of: recurringExpenses) { _, newValue in
            viewModel.configure(expenses: newValue, modelContext: modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        RecurringExpensesView()
            .modelContainer(for: RecurringExpense.self)
    }
}
