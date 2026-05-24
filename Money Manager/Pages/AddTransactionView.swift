import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.persistence) private var persistence
    @Query(sort: \Category.name) private var customCategories: [Category]

    @State private var viewModel: AddTransactionViewModel

    @State private var saveSuccess = false
    @State private var errorTriggered = 0

    init(mode: AddTransactionMode, groupService: GroupServiceProtocol = GroupService.shared) {
        _viewModel = State(wrappedValue: AddTransactionViewModel(mode: mode, groupService: groupService))
    }

    var body: some View {
        NavigationStack {
            sharedForm
        }
        .task { viewModel.persistence = persistence }
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

#Preview("Group Transaction") {
    let aliceId = UUID()
    let alice = GroupMember(from: APIGroupMember(id: aliceId, email: "alice@example.com", username: "alice", joinedAt: Date()))
    let bob   = GroupMember(from: APIGroupMember(id: UUID(), email: "bob@example.com",   username: "bob",   joinedAt: Date()))
    let group = SplitGroup(id: UUID(), name: "Weekend Trip", createdBy: aliceId, createdAt: Date(), members: [alice, bob], balances: [], settlements: [])
    AddTransactionView(mode: .shared(group: group, members: [alice, bob], onAdd: { _ in }), groupService: GroupService.shared)
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
