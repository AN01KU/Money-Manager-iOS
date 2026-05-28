import SwiftUI
import SwiftData

struct TransactionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.persistence) private var persistence
    @Query(sort: \Category.name) private var customCategories: [Category]
    @Query private var allRecurring: [RecurringTransaction]

    @State private var viewModel: TransactionEditorViewModel

    @State private var errorTriggered = 0
    @State private var editTapped = 0
    @State private var deleteTapped = 0
    @State private var editingTransaction: Transaction?

    init(mode: EditorMode = .create) {
        _viewModel = State(wrappedValue: TransactionEditorViewModel(mode: mode))
    }

    private var linkedRecurring: RecurringTransaction? {
        guard let rid = viewModel.mode.transaction?.recurringExpenseId else { return nil }
        return allRecurring.first { $0.id == rid }
    }

    var body: some View {
        NavigationStack {
            if viewModel.mode.isReadOnly {
                viewScrollView
            } else {
                personalScrollView
            }
        }
        .task { viewModel.persistence = persistence }
        .sheet(item: $editingTransaction) { txn in
            TransactionEditorView(mode: .edit(txn))
        }
        .alert("Delete transaction?", isPresented: $viewModel.showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.delete { dismiss() }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Update Recurring Transaction?", isPresented: $viewModel.showRecurringAmountAlert) {
            Button("Update Recurring Too") {
                viewModel.saveAlsoUpdatingRecurring { dismiss() }
            }
            Button("Just This Transaction", role: .cancel) {
                viewModel.saveThisTransactionOnly { dismiss() }
            }
        } message: {
            Text("You've changed fields that are part of the recurring schedule. Update the template too?")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sensoryFeedback(.error, trigger: errorTriggered)
        .onChange(of: viewModel.errorMessage) { _, newVal in
            if newVal != nil { errorTriggered += 1 }
        }
    }

    // MARK: - View mode (read-only detail)

    private var viewScrollView: some View {
        ScrollView {
            VStack(spacing: AppConstants.UI.spacing20) {
                viewHeroSection

                if let tx = viewModel.mode.transaction {
                    if viewModel.isSettlementTransaction {
                        SettlementTransactionContent(groupName: tx.groupName, groupId: tx.groupId, onDismiss: { dismiss() })
                            .padding(.horizontal, AppConstants.UI.padding)
                    }

                    if viewModel.isGroupTransaction {
                        GroupTransactionContent(groupName: tx.groupName, groupId: tx.groupId, onDismiss: { dismiss() })
                            .padding(.horizontal, AppConstants.UI.padding)
                    }

                    if let recurring = linkedRecurring {
                        viewRecurringBanner(recurring)
                    }

                    viewDetailsCard(tx)
                }

                viewActionButtons
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
        .task { viewModel.customCategories = customCategories }
        .onChange(of: customCategories) { _, newValue in viewModel.customCategories = newValue }
    }

    private var viewHeroSection: some View {
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

            if let tx = viewModel.mode.transaction {
                Text((tx.type == .income ? "+" : "-") + CurrencyFormatter.format(tx.amount))
                    .font(AppTypography.amountHero)
                    .foregroundStyle(tx.type == .income ? AppColors.income : AppColors.expense)
                    .accessibilityIdentifier("transaction-detail.amount")

                Text(viewModel.formatDateAndTime(tx.date, time: tx.time))
                    .font(AppTypography.subhead)
                    .foregroundStyle(AppColors.label2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppConstants.UI.spacingSM)
    }

    private func viewRecurringBanner(_ recurring: RecurringTransaction) -> some View {
        Button {
        } label: {
            HStack(spacing: AppConstants.UI.spacing12) {
                AppIcon(name: AppIcons.UI.recurring, size: 20, color: AppColors.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recurring · \(recurring.frequency.rawValue.capitalized)")
                        .font(AppTypography.subhead)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.primary)

                    if let next = recurring.nextOccurrence {
                        Text("Next: \(next.formattedNextOccurrence())")
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

    private func viewDetailsCard(_ tx: Transaction) -> some View {
        VStack(spacing: 0) {
            if let description = tx.transactionDescription, !description.isEmpty {
                DetailInfoRow(label: "Description", value: description)
                Divider().padding(.leading, AppConstants.UI.padding)
            }

            if let notes = tx.notes, !notes.isEmpty {
                DetailInfoRow(label: "Notes", value: notes)
                Divider().padding(.leading, AppConstants.UI.padding)
            }

            DetailInfoRow(
                label: "Type",
                value: tx.type == .income ? "Income" : "Expense",
                valueColor: tx.type == .income ? AppColors.income : AppColors.expense
            )
            Divider().padding(.leading, AppConstants.UI.padding)

            DetailInfoRow(label: "Category", value: viewModel.categoryName)

            if let recurring = linkedRecurring {
                Divider().padding(.leading, AppConstants.UI.padding)
                DetailInfoRow(label: "Recurring", value: recurring.frequency.rawValue.capitalized)
            }

            Divider().padding(.leading, AppConstants.UI.padding)
            DetailInfoRow(label: "Date", value: viewModel.formatFullDate(tx.date))

            if tx.updatedAt > tx.createdAt {
                Divider().padding(.leading, AppConstants.UI.padding)
                DetailInfoRow(label: "Last Modified", value: viewModel.formatFullDate(tx.updatedAt))
            }
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .padding(.horizontal, AppConstants.UI.padding)
    }

    private var viewActionButtons: some View {
        HStack(spacing: AppConstants.UI.spacing12) {
            Button {
                editTapped += 1
                if let tx = viewModel.mode.transaction {
                    editingTransaction = tx
                }
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

    // MARK: - Personal (card-based ScrollView)

    private var personalScrollView: some View {
        ScrollView {
            VStack(spacing: AppConstants.UI.spacing20) {
                AmountCard(viewModel: viewModel)
                typeSegment
                DateRow(viewModel: viewModel)
                detailsCard
                RecurringSection(viewModel: viewModel)
            }
            .padding(.horizontal, AppConstants.UI.padding)
            .padding(.top, AppConstants.UI.spacing12)
            .padding(.bottom, AppConstants.UI.spacingXL)
        }
        .background(AppColors.background)
        .dismissKeyboardOnScroll()
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(viewModel.navigationTitleIdentifier)
        .toolbar { personalToolbar }
        .navigationDestination(isPresented: $viewModel.showCategoryPicker) {
            CategoryPickerView(selectedCategoryId: $viewModel.selectedCategoryId)
        }
        .task { viewModel.customCategories = customCategories }
        .onChange(of: customCategories) { _, newValue in viewModel.customCategories = newValue }
    }

    // MARK: - Type segment

    private var typeSegment: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                let selected = viewModel.transactionType == type
                Button {
                    viewModel.transactionType = type
                } label: {
                    Text(type.rawValue)
                        .font(AppTypography.body)
                        .fontWeight(selected ? .semibold : .regular)
                        .foregroundStyle(selected ? AppColors.label : AppColors.label2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            selected
                                ? RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius - 2)
                                    .fill(AppColors.surface)
                                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(AppColors.surface2)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }

    // MARK: - Details card

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
            Text("DETAILS")
                .font(AppTypography.footnote)
                .fontWeight(.semibold)
                .tracking(AppTypography.trackingFootnote)
                .foregroundStyle(AppColors.label2)
                .padding(.leading, AppConstants.UI.spacingXS)

            TxnCard {
                VStack(spacing: 0) {
                    TextField(
                        viewModel.isRecurring ? "Name * (e.g., Rent, Netflix)" : "Description (e.g., Lunch at cafe)",
                        text: $viewModel.description
                    )
                    .font(AppTypography.body)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityIdentifier("description-field")

                    Divider().padding(.vertical, AppConstants.UI.spacingSM)

                    TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                        .font(AppTypography.body)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                }
            }
        }
    }

    // MARK: - Toolbar

    private var personalToolbar: some ToolbarContent {
        EditorToolbar(
            isSaving: viewModel.isSaving,
            isValid: viewModel.canSave,
            onCancel: { dismiss() },
            onSave: { viewModel.save { dismiss() } }
        )
    }
}

// MARK: - Detail row components (shared with GroupTransactionDetailSheet)

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

// MARK: - Previews

#Preview("New Transaction") {
    TransactionEditorView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}

#Preview("Edit Transaction") {
    let transaction = Transaction(amount: 450, categoryId: UUID(), date: Date(),
                                  transactionDescription: "Lunch at cafe", notes: "With colleagues")
    TransactionEditorView(mode: .edit(transaction))
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}

#Preview("View Transaction") {
    let transaction = Transaction(amount: 450, categoryId: UUID(), date: Date(),
                                  transactionDescription: "Lunch at cafe", notes: "With colleagues")
    TransactionEditorView(mode: .view(transaction))
        .modelContainer(for: [Transaction.self, Category.self, RecurringTransaction.self], inMemory: true)
}
