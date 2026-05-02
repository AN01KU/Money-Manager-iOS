import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    @Query private var allRecurring: [RecurringTransaction]

    let transaction: Transaction
    var onEdit: ((Transaction) -> Void)?
    @State private var viewModel: TransactionDetailViewModel
    @State private var editTapped = 0
    @State private var deleteTapped = 0
    @State private var deleteSuccess = false

    init(transaction: Transaction, onEdit: ((Transaction) -> Void)? = nil) {
        self.transaction = transaction
        self.onEdit = onEdit
        self._viewModel = State(wrappedValue: TransactionDetailViewModel(transaction: transaction))
    }

    private var linkedRecurring: RecurringTransaction? {
        guard let rid = transaction.recurringExpenseId else { return nil }
        return allRecurring.first { $0.id == rid }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.UI.spacing20) {
                    heroSection

                    if viewModel.isSettlementTransaction {
                        SettlementTransactionContent(groupName: transaction.groupName, groupId: transaction.groupId, onDismiss: { dismiss() })
                            .padding(.horizontal, AppConstants.UI.padding)
                    }

                    if viewModel.isGroupTransaction {
                        GroupTransactionContent(groupName: transaction.groupName, groupId: transaction.groupId, onDismiss: { dismiss() })
                            .padding(.horizontal, AppConstants.UI.padding)
                    }

                    if let recurring = linkedRecurring {
                        recurringBanner(recurring)
                    }

                    detailsCard
                    actionButtons
                }
                .padding(.top, AppConstants.UI.spacing12)
                .padding(.bottom, AppConstants.UI.spacingXL)
            }
            .background(AppColors.background)
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
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
        VStack(spacing: AppConstants.UI.spacingSM) {
            ZStack {
                Circle()
                    .fill(viewModel.categoryColor.opacity(0.15))
                    .frame(width: 72, height: 72)
                AppIcon(name: viewModel.categoryIcon, size: 32, color: viewModel.categoryColor)
            }

            Text(viewModel.categoryName)
                .font(AppTypography.subhead)
                .foregroundStyle(AppColors.label2)

            Text((transaction.type == .income ? "+" : "-") + CurrencyFormatter.format(transaction.amount))
                .font(AppTypography.amountHero)
                .foregroundStyle(transaction.type == .income ? AppColors.income : AppColors.expense)
                .accessibilityIdentifier("transaction-detail.amount")

            Text(viewModel.formatDateAndTime(transaction.date, time: transaction.time))
                .font(AppTypography.subhead)
                .foregroundStyle(AppColors.label2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppConstants.UI.spacingSM)
    }

    // MARK: - Recurring banner

    private func recurringBanner(_ recurring: RecurringTransaction) -> some View {
        Button {
            // navigate to recurring detail — no-op for now
        } label: {
            HStack(spacing: AppConstants.UI.spacing12) {
                AppIcon(name: AppIcons.UI.recurring, size: 20, color: AppColors.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recurring · \(recurring.frequency.rawValue.capitalized)")
                        .font(AppTypography.subhead)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.primary)

                    if let next = recurring.nextOccurrence {
                        Text("Next: \(next.formatted(date: .abbreviated, time: .omitted))")
                            .font(AppTypography.caption1)
                            .foregroundStyle(AppColors.label2)
                    }
                }

                Spacer()

                AppIcon(name: AppIcons.UI.chevron, size: 14, color: AppColors.label3)
            }
            .padding(AppConstants.UI.padding)
            .background(AppColors.primaryBg)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppConstants.UI.padding)
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            if let description = transaction.transactionDescription, !description.isEmpty {
                DetailInfoRow(label: "Description", value: description)
                Divider().padding(.leading, AppConstants.UI.padding)
            }

            if let notes = transaction.notes, !notes.isEmpty {
                DetailInfoRow(label: "Notes", value: notes)
                Divider().padding(.leading, AppConstants.UI.padding)
            }

            DetailInfoRow(
                label: "Type",
                value: transaction.type == .income ? "Income" : "Expense",
                valueColor: transaction.type == .income ? AppColors.income : AppColors.expense
            )
            Divider().padding(.leading, AppConstants.UI.padding)

            DetailInfoRow(label: "Category", value: viewModel.categoryName)

            if let recurring = linkedRecurring {
                Divider().padding(.leading, AppConstants.UI.padding)
                DetailInfoRow(label: "Recurring", value: recurring.frequency.rawValue.capitalized)
            }

            Divider().padding(.leading, AppConstants.UI.padding)
            DetailInfoRow(label: "Date", value: viewModel.formatFullDate(transaction.date))

            if transaction.updatedAt > transaction.createdAt {
                Divider().padding(.leading, AppConstants.UI.padding)
                DetailInfoRow(label: "Last Modified", value: viewModel.formatFullDate(transaction.updatedAt))
            }
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .padding(.horizontal, AppConstants.UI.padding)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: AppConstants.UI.spacing12) {
            Button {
                editTapped += 1
                onEdit?(transaction)
            } label: {
                HStack(spacing: AppConstants.UI.spacingSM) {
                    AppIcon(name: AppIcons.UI.edit, size: 18, color: .white)
                    Text("Edit")
                        .font(AppTypography.button)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
            }
            .sensoryFeedback(.impact(weight: .light), trigger: editTapped)
            .accessibilityIdentifier("transaction-detail.edit-button")

            Button {
                deleteTapped += 1
                viewModel.showDeleteAlert = true
            } label: {
                HStack(spacing: AppConstants.UI.spacingSM) {
                    AppIcon(name: AppIcons.UI.delete, size: 18, color: AppColors.expense)
                    Text("Delete")
                        .font(AppTypography.button)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.expense.opacity(0.1))
                .foregroundStyle(AppColors.expense)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
            }
            .sensoryFeedback(.warning, trigger: deleteTapped)
            .accessibilityIdentifier("transaction-detail.delete-button")
        }
        .padding(.horizontal, AppConstants.UI.padding)
    }
}

// MARK: - Detail Info Row

struct DetailInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = AppColors.label

    var body: some View {
        HStack(spacing: AppConstants.UI.spacing12) {
            Text(label)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.label2)
            Spacer()
            Text(value)
                .font(AppTypography.body)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, AppConstants.UI.padding)
        .padding(.vertical, 14)
    }
}

// MARK: - Legacy rows (kept for other callers)

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

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Text(value).font(.body).foregroundStyle(.primary)
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
