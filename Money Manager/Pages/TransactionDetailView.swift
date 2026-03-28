import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    @Query private var groupTransactions: [GroupTransactionModel]
    let transaction: Transaction
    @State private var viewModel: TransactionDetailViewModel
    @State private var editTapped = false
    @State private var deleteTapped = false
    @State private var deleteSuccess = false

    init(transaction: Transaction) {
        self.transaction = transaction
        _viewModel = State(wrappedValue: TransactionDetailViewModel(transaction: transaction))
    }

    private var groupName: String? {
        guard let id = transaction.groupTransactionId else { return nil }
        return groupTransactions.first(where: { $0.id == id })?.group?.name
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isGroupTransaction {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(AppColors.accent)
                                Text("Group Transaction")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.accent)
                                Spacer()
                            }
                            
                            GroupTransactionContent(groupName: groupName)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(viewModel.categoryColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: viewModel.categoryIcon)
                                .font(.system(size: 40))
                                .foregroundStyle(viewModel.categoryColor)
                        }
                        
                        Text(transaction.category)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(CurrencyFormatter.format(transaction.amount))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(transaction.type == "income" ? AppColors.positive : AppColors.expense)
                        
                        Text(viewModel.formatDateAndTime(transaction.date, time: transaction.time))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        if let description = transaction.transactionDescription, !description.isEmpty {
                            DetailRow(label: "Description", value: description)
                        }
                        
                        if let notes = transaction.notes, !notes.isEmpty {
                            DetailRow(label: "Notes", value: notes)
                        }
                        
                        DetailRow(label: "Type", value: transaction.type == "income" ? "Income" : "Expense")

                        DetailRow(label: "Category", value: transaction.category)
                        
                        DetailRow(label: "Created", value: viewModel.formatFullDate(transaction.createdAt))
                        
                        if transaction.updatedAt != transaction.createdAt {
                            DetailRow(label: "Last Modified", value: viewModel.formatFullDate(transaction.updatedAt))
                        }
                        
                        if transaction.recurringExpenseId != nil {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundStyle(AppColors.accent)
                                Text("This is a recurring transaction")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(AppColors.accentLight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            editTapped = true
                            viewModel.showEditSheet = true
                        }) {
                            Text("Edit")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.accent)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .sensoryFeedback(.impact(weight: .light), trigger: editTapped)
                        .onChange(of: editTapped) { _, newValue in
                            if newValue { editTapped = false }
                        }
                        
                        Button(action: {
                            deleteTapped = true
                            viewModel.showDeleteAlert = true
                        }) {
                            Text("Delete")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.expense)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .sensoryFeedback(.warning, trigger: deleteTapped)
                        .onChange(of: deleteTapped) { _, newValue in
                            if newValue { deleteTapped = false }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showEditSheet) {
                AddTransactionView(transactionToEdit: transaction)
            }
            .alert("Delete transaction?", isPresented: $viewModel.showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteTransaction { deleteSuccess = true; dismiss() }
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .task {
                viewModel.modelContext = modelContext
                viewModel.customCategories = customCategories
            }
            .onChange(of: customCategories) { _, newValue in
                viewModel.customCategories = newValue
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
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    TransactionDetailView(transaction: Transaction(
        amount: 450,
        category: "Food & Dining",
        date: Date(),
        time: Date(),
        transactionDescription: "Lunch at cafe"
    ))
}
