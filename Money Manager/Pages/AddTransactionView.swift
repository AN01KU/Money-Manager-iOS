import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.persistence) private var persistence
    @Query(sort: \Category.name) private var customCategories: [Category]

    @State private var viewModel: AddTransactionViewModel

    @State private var saveSuccess = false
    @State private var errorTriggered = 0

    init(mode: AddTransactionMode = .personal(), groupService: GroupServiceProtocol = GroupService.shared) {
        _viewModel = State(wrappedValue: AddTransactionViewModel(mode: mode, groupService: groupService))
    }

    init(transactionToEdit: Transaction) {
        _viewModel = State(wrappedValue: AddTransactionViewModel(mode: .personal(editing: transactionToEdit)))
    }

    var body: some View {
        NavigationStack {
            if viewModel.isShared {
                sharedForm
            } else {
                personalScrollView
            }
        }
        .task { viewModel.persistence = persistence }
        .alert("Update Recurring Transaction?", isPresented: $viewModel.showRecurringAmountAlert) {
            Button("Update Recurring Too") {
                viewModel.saveAlsoUpdatingRecurring { saveSuccess = true; dismiss() }
            }
            Button("Just This Transaction", role: .cancel) {
                viewModel.saveThisTransactionOnly { saveSuccess = true; dismiss() }
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

    // MARK: - Personal (card-based ScrollView)

    private var personalScrollView: some View {
        ScrollView {
            VStack(spacing: AppConstants.UI.spacing20) {
                AmountCard(viewModel: viewModel, customCategories: customCategories)
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
            CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
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
            isValid: viewModel.isValid,
            onCancel: { dismiss() },
            onSave: { viewModel.save(completion: { saveSuccess = true; dismiss() }) }
        )
    }

    // MARK: - Shared form (BAU — unchanged layout)

    private var sharedForm: some View {
        Form {
            AddTransactionAmountSection(viewModel: viewModel, customCategories: customCategories)

            if viewModel.isEditingShared {
                AddTransactionPaidBySection(viewModel: viewModel)
                Section {
                    Label("Amount and split cannot be changed after creation.", systemImage: "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                AddTransactionPaidBySection(viewModel: viewModel)
                SplitSection(viewModel: viewModel)
                AddTransactionSplitMembersSection(viewModel: viewModel)
            }

            AddTransactionSharedDescriptionSection(viewModel: viewModel)
        }
        .dismissKeyboardOnScroll()
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(viewModel.navigationTitleIdentifier)
        .toolbar {
            EditorToolbar(
                isSaving: viewModel.isSaving,
                isValid: viewModel.isValid,
                onCancel: { dismiss() },
                onSave: { viewModel.save(completion: { saveSuccess = true; dismiss() }) }
            )
        }
        .task { viewModel.customCategories = customCategories }
        .onChange(of: customCategories) { _, newValue in viewModel.customCategories = newValue }
    }
}

// MARK: - Reusable card wrapper

struct TxnCard<Content: View>: View {
    var padding: CGFloat = AppConstants.UI.padding
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }
}

// MARK: - Picker row

struct TxnPickerRow<Picker: View>: View {
    let label: String
    @ViewBuilder let picker: Picker

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
            Spacer()
            picker
        }
    }
}

// MARK: - Shared sections (BAU)

private struct AddTransactionAmountSection: View {
    @Bindable var viewModel: AddTransactionViewModel
    let customCategories: [Category]
    @State private var categoryTapped = 0

    private var categoryByKey: [String: TransactionCategory] {
        Dictionary(
            uniqueKeysWithValues: TransactionCategory.merge(overrides: customCategories)
                .filter { !$0.isHidden }
                .map { ($0.key, $0) }
        )
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount *").font(.subheadline).foregroundStyle(.secondary)
                TextField("0.00", text: $viewModel.amount)
                    .keyboardType(.decimalPad)
                    .font(.title2).fontWeight(.semibold)
                    .disabled(viewModel.isEditingShared)
                    .foregroundStyle(viewModel.isEditingShared ? .secondary : .primary)
                    .accessibilityIdentifier("amount-field")
            }
            .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Category *").font(.subheadline).foregroundStyle(.secondary)
                Button {
                    categoryTapped += 1
                    viewModel.showCategoryPicker = true
                } label: {
                    HStack {
                        if let cat = categoryByKey[viewModel.selectedCategory] {
                            AppIcon(name: cat.icon, size: 20, color: cat.color)
                            Text(cat.name)
                        } else {
                            Text(viewModel.selectedCategory.isEmpty ? "Select Category" : viewModel.selectedCategory)
                                .foregroundStyle(viewModel.selectedCategory.isEmpty ? .secondary : .primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.down").foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(AppColors.inputBackground)
                    .clipShape(.rect(cornerRadius: 8))
                }
                .sensoryFeedback(.impact(weight: .light), trigger: categoryTapped)
                .accessibilityIdentifier("category-picker-button")
            }
            .padding(.vertical, 8)
        }
    }
}

private struct AddTransactionSharedDescriptionSection: View {
    @Bindable var viewModel: AddTransactionViewModel
    var body: some View {
        Section("Details") {
            TextField("Description * (e.g., Dinner, Cab)", text: $viewModel.description)
                .textInputAutocapitalization(.sentences)
            TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6).textInputAutocapitalization(.sentences)
        }
    }
}

private struct AddTransactionPaidBySection: View {
    @Bindable var viewModel: AddTransactionViewModel
    var body: some View {
        Section("Paid By") {
            if case .shared(_, let members, _, _, _) = viewModel.mode {
                ForEach(members) { member in
                    let isSelected = viewModel.paidByUserId == member.id
                    Button { viewModel.paidByUserId = member.id } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.displayName(for: member)).foregroundStyle(.primary)
                                Text(member.email).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isSelected { Image(systemName: "checkmark").font(.subheadline.weight(.semibold)).foregroundStyle(.primary) }
                        }
                    }
                    .listRowBackground(isSelected ? AppColors.chipBackground : AppColors.surface)
                }
            }
        }
    }
}

private struct AddTransactionSplitMembersSection: View {
    @Bindable var viewModel: AddTransactionViewModel
    var body: some View {
        Section("Split Between") {
            if case .shared(_, let members, _, _, _) = viewModel.mode {
                ForEach(members) { member in
                    let isIncluded = viewModel.selectedMembers.contains(member.id)
                    Button { viewModel.toggleMember(member.id) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.displayName(for: member)).foregroundStyle(.primary)
                                Text(member.email).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.splitType == .custom && isIncluded {
                                TextField("0.00", text: viewModel.customAmountBinding(for: member.id))
                                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                                    .frame(width: 80).fontWeight(.medium).foregroundStyle(.primary)
                            } else if viewModel.splitType == .equal && isIncluded {
                                Text(viewModel.equalShareText).font(.subheadline).foregroundStyle(.secondary)
                            }
                            if isIncluded {
                                Image(systemName: "checkmark").font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary).padding(.leading, 4)
                            }
                        }
                    }
                    .listRowBackground(isIncluded ? AppColors.chipBackground : AppColors.surface)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("New Transaction") {
    AddTransactionView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}

#Preview("Edit Transaction") {
    let transaction = Transaction(amount: 450, category: "Food & Dining", date: Date(), transactionDescription: "Lunch at cafe", notes: "With colleagues")
    AddTransactionView(transactionToEdit: transaction)
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}

#Preview("Group Transaction") {
    let groupId = UUID()
    let alice = APIGroupMember(id: UUID(), email: "alice@example.com", username: "alice", joinedAt: Date())
    let bob   = APIGroupMember(id: UUID(), email: "bob@example.com",   username: "bob",   joinedAt: Date())
    let group = APIGroupWithDetails(id: groupId, name: "Weekend Trip", createdBy: alice.id, createdAt: Date(), members: [alice, bob], balances: [])
    AddTransactionView(mode: .shared(group: group, members: [alice, bob], onAdd: { _ in }), groupService: GroupService.shared)
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
