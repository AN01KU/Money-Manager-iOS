import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    let transaction: Transaction
    @State private var viewModel: TransactionDetailViewModel
    @State private var editTapped = 0
    @State private var deleteTapped = 0
    @State private var deleteSuccess = false

    init(transaction: Transaction) {
        self.transaction = transaction
        self._viewModel = State(wrappedValue: TransactionDetailViewModel(transaction: transaction))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero
                    heroSection

                    // Settlement banner
                    if viewModel.isSettlementTransaction {
                        SettlementTransactionContent(groupName: transaction.groupName, groupId: transaction.groupId, onDismiss: { dismiss() })
                            .padding(.horizontal)
                    }

                    // Group banner (single, no duplication)
                    if viewModel.isGroupTransaction {
                        GroupTransactionContent(groupName: transaction.groupName, groupId: transaction.groupId, onDismiss: { dismiss() })
                            .padding(.horizontal)
                    }

                    // Details card
                    detailsCard

                    // Actions
                    actionButtons
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(viewModel.categoryColor.opacity(0.15))
                    .frame(width: 72, height: 72)
                AppIcon(name: viewModel.categoryIcon, size: 32, color: viewModel.categoryColor)
            }

            Text(transaction.category)
                .font(AppTypography.heroCategory)
                .foregroundStyle(.secondary)

            Text((transaction.type == .income ? "+" : "-") + CurrencyFormatter.format(transaction.amount))
                .font(AppTypography.amountHero)
                .foregroundStyle(transaction.type == .income ? AppColors.positive : AppColors.expense)
                .accessibilityIdentifier("transaction-detail.amount")

            Text(viewModel.formatDateAndTime(transaction.date, time: transaction.time))
                .font(AppTypography.heroDate)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            if let description = transaction.transactionDescription, !description.isEmpty {
                InfoRow(label: "Description", value: description)
                Divider().padding(.leading, 16)
            }

            if let notes = transaction.notes, !notes.isEmpty {
                InfoRow(label: "Notes", value: notes)
                Divider().padding(.leading, 16)
            }

            InfoRow(
                label: "Type",
                value: transaction.type == .income ? "Income" : "Expense",
                valueColor: transaction.type == .income ? AppColors.positive : AppColors.expense
            )
            Divider().padding(.leading, 16)

            InfoRow(label: "Category", value: transaction.category)
            Divider().padding(.leading, 16)

            InfoRow(label: "Date", value: viewModel.formatFullDate(transaction.date))

            if transaction.updatedAt > transaction.createdAt {
                Divider().padding(.leading, 16)
                InfoRow(label: "Last Modified", value: viewModel.formatFullDate(transaction.updatedAt))
            }

            if transaction.recurringExpenseId != nil {
                Divider().padding(.leading, 16)
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(AppTypography.infoLabel)
                        .foregroundStyle(AppColors.accent)
                    Text("Recurring transaction")
                        .font(AppTypography.infoLabel)
                        .foregroundStyle(AppColors.accent)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 1)
        }
        .padding(.horizontal)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                editTapped += 1
                viewModel.showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
                    .font(AppTypography.button)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .sensoryFeedback(.impact(weight: .light), trigger: editTapped)
            .accessibilityIdentifier("transaction-detail.edit-button")

            Button {
                deleteTapped += 1
                viewModel.showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(AppTypography.button)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.expense.opacity(0.1))
                    .foregroundStyle(AppColors.expense)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .sensoryFeedback(.warning, trigger: deleteTapped)
            .accessibilityIdentifier("transaction-detail.delete-button")
        }
        .padding(.horizontal)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(AppTypography.infoLabel)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)

            Text(value)
                .font(AppTypography.infoValue)
                .foregroundStyle(valueColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Legacy DetailRow (kept for other callers)

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
        transactionDescription: "Lunch at cafe",
        notes: "With the team"
    ))
}
