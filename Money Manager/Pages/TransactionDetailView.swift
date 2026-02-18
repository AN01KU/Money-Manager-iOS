import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let expense: Expense
    @StateObject private var viewModel: TransactionDetailViewModel
    
    init(expense: Expense) {
        self.expense = expense
        _viewModel = StateObject(wrappedValue: TransactionDetailViewModel(expense: expense))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isGroupExpense {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.teal)
                                Text("Group Expense")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.teal)
                                Spacer()
                            }
                            
                            NavigationLink(value: viewModel.getGroupForNavigation()) { 
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(expense.groupName ?? "Unknown Group")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text("Tap to view group details")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.teal.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill((viewModel.category?.color ?? Color.gray).opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: viewModel.category?.icon ?? "ellipsis.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(viewModel.category?.color ?? Color.gray)
                        }
                        
                        Text(expense.category)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("₹\(viewModel.formatAmount(expense.amount))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.red)
                        
                        Text(viewModel.formatDateAndTime(expense.date, time: expense.time))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        if let description = expense.expenseDescription, !description.isEmpty {
                            DetailRow(label: "Description", value: description)
                        }
                        
                        if let notes = expense.notes, !notes.isEmpty {
                            DetailRow(label: "Notes", value: notes)
                        }
                        
                        DetailRow(label: "Category", value: expense.category)
                        
                        DetailRow(label: "Created", value: viewModel.formatFullDate(expense.createdAt))
                        
                        if expense.updatedAt != expense.createdAt {
                            DetailRow(label: "Last Modified", value: viewModel.formatFullDate(expense.updatedAt))
                        }
                        
                        if expense.isRecurring {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.teal)
                                Text("This is a recurring expense")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.teal.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.showEditSheet = true
                        }) {
                            Text("Edit")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.teal)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            viewModel.showDeleteAlert = true
                        }) {
                            Text("Delete")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SplitGroup.self) { group in
                GroupDetailView(group: group)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showEditSheet) {
                AddExpenseView(expenseToEdit: expense)
            }
            .alert("Delete Expense?", isPresented: $viewModel.showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteExpense { dismiss() }
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    TransactionDetailView(expense: Expense(
        amount: 450,
        category: "Food & Dining",
        date: Date(),
        time: Date(),
        expenseDescription: "Lunch at cafe"
    ))
}
