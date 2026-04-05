import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Transaction> { !$0.isSoftDeleted }, sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    @State private var viewModel = TransactionsViewModel()
    var categoryFilter: Binding<String?>?
    var onGroupTapped: ((UUID) -> Void)?

    var body: some View {
        NavigationStack {
            TransactionsBody(viewModel: viewModel, onGroupTapped: onGroupTapped)
                .navigationTitle("Transactions")
        }
        .task {
            viewModel.modelContext = modelContext
            viewModel.update(allTransactions: allTransactions, customCategories: customCategories)
        }
        .onChange(of: allTransactions) { _, newValue in
            viewModel.update(allTransactions: newValue, customCategories: customCategories)
        }
        .onChange(of: customCategories) { _, newValue in
            viewModel.update(allTransactions: allTransactions, customCategories: newValue)
        }
        .onChange(of: categoryFilter?.wrappedValue) { _, newValue in
            guard let category = newValue else { return }
            withAnimation {
                viewModel.selectedCategoryFilter = category
                viewModel.transactionTypeFilter = .expenses
            }
            categoryFilter?.wrappedValue = nil
        }
    }
}

// MARK: - Body

private struct TransactionsBody: View {
    @Bindable var viewModel: TransactionsViewModel
    var onGroupTapped: ((UUID) -> Void)?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Month selector + filter chips
                    TransactionsFilterBar(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    TransactionsMonthSelector(viewModel: viewModel)
                        .padding(.horizontal)

                    if let categoryFilter = viewModel.selectedCategoryFilter {
                        HStack(spacing: 8) {
                            Label(categoryFilter, systemImage: "line.3.horizontal.decrease.circle.fill")
                                .font(AppTypography.infoValue)

                            Button {
                                withAnimation { viewModel.selectedCategoryFilter = nil }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(AppTypography.infoLabel)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppColors.accentLight)
                        .clipShape(Capsule())
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if viewModel.filteredTransactions.isEmpty {
                        EmptyStateView(
                            icon: "tray",
                            title: viewModel.transactionTypeFilter == .income ? "No income yet" : "No transactions yet",
                            message: "Tap + to add your first \(viewModel.transactionTypeFilter == .income ? "income" : "expense")"
                        )
                        .padding(.horizontal)
                        .padding(.top, 40)
                    } else {
                        TransactionList(
                            transactions: viewModel.filteredTransactions,
                            onDelete: { transaction in viewModel.deleteTransaction(transaction) },
                            onGroupTapped: onGroupTapped
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 100)
            }

            FloatingActionButton(icon: "plus") {
                viewModel.showAddTransaction = true
            }
            .padding(.trailing, 24)
            .padding(.bottom, 24)
            .accessibilityIdentifier("transactions.add-button")
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $viewModel.searchText, prompt: "Search transactions")
        .sheet(isPresented: $viewModel.showAddTransaction) { AddTransactionView() }
        .alert("Delete Transaction?", isPresented: Binding(
            get: { viewModel.transactionToDelete != nil },
            set: { if !$0 { viewModel.cancelDeleteTransaction() } }
        )) {
            Button("Cancel", role: .cancel) { viewModel.cancelDeleteTransaction() }
            Button("Delete", role: .destructive) { viewModel.confirmDeleteTransaction() }
        } message: {
            if let transaction = viewModel.transactionToDelete {
                Text("Are you sure you want to delete \"\(transaction.transactionDescription ?? transaction.category)\"? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Month Selector

private struct TransactionsMonthSelector: View {
    @Bindable var viewModel: TransactionsViewModel
    @State private var showDatePicker = false
    @State private var tapped = 0

    private var formattedMonth: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: viewModel.selectedDate)
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                if let prev = Calendar.current.date(byAdding: .month, value: -1, to: viewModel.selectedDate) {
                    viewModel.selectedDate = prev
                    tapped += 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(AppTypography.cardLabel)
                    .foregroundStyle(AppColors.accent)
                    .padding(6)
            }
            .buttonStyle(.plain)

            Button {
                showDatePicker = true
            } label: {
                Text(formattedMonth)
                    .font(AppTypography.chipSelected)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Button {
                if let next = Calendar.current.date(byAdding: .month, value: 1, to: viewModel.selectedDate) {
                    viewModel.selectedDate = next
                    tapped += 1
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(AppTypography.cardLabel)
                    .foregroundStyle(AppColors.accent)
                    .padding(6)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .sensoryFeedback(.impact(weight: .light), trigger: tapped)
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker("Select Month", selection: $viewModel.selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .padding()
                    .navigationTitle("Select Month")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showDatePicker = false }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Filter Bar

private struct TransactionsFilterBar: View {
    @Bindable var viewModel: TransactionsViewModel
    @State private var selectionChanged = 0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TransactionTypeFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.transactionTypeFilter = filter
                    }
                    selectionChanged += 1
                } label: {
                    Text(filter.rawValue)
                        .font(viewModel.transactionTypeFilter == filter ? AppTypography.chipSelected : AppTypography.chip)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(viewModel.transactionTypeFilter == filter ? AppColors.accent : Color(.systemGray5))
                        .foregroundStyle(viewModel.transactionTypeFilter == filter ? .white : .primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .sensoryFeedback(.selection, trigger: selectionChanged)
    }
}
