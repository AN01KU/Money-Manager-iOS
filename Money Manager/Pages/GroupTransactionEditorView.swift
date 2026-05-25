import SwiftUI
import SwiftData

struct GroupTransactionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var customCategories: [Category]

    @State private var viewModel: GroupTransactionEditorViewModel

    @State private var saveSuccess = false
    @State private var errorTriggered = 0

    init(mode: GroupEditorMode, groupService: GroupServiceProtocol = GroupService.shared) {
        _viewModel = State(wrappedValue: GroupTransactionEditorViewModel(mode: mode, groupService: groupService))
    }

    var body: some View {
        NavigationStack {
            groupForm
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

    private var groupForm: some View {
        Form {
            GroupEditorAmountSection(viewModel: viewModel, customCategories: customCategories)

            if viewModel.isEditingExisting {
                GroupEditorPaidBySection(viewModel: viewModel)
                Section {
                    Label("Amount and split cannot be changed after creation.", systemImage: "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                GroupEditorPaidBySection(viewModel: viewModel)
                SplitSectionGroup(viewModel: viewModel)
                GroupEditorSplitMembersSection(viewModel: viewModel)
            }

            GroupEditorDescriptionSection(viewModel: viewModel)
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
                onSave: { viewModel.save { saveSuccess = true; dismiss() } }
            )
        }
        .task { viewModel.customCategories = customCategories }
        .onChange(of: customCategories) { _, newValue in viewModel.customCategories = newValue }
    }
}

// MARK: - Sections

private struct GroupEditorAmountSection: View {
    @Bindable var viewModel: GroupTransactionEditorViewModel
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
                    .disabled(viewModel.isEditingExisting)
                    .foregroundStyle(viewModel.isEditingExisting ? .secondary : .primary)
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

private struct GroupEditorDescriptionSection: View {
    @Bindable var viewModel: GroupTransactionEditorViewModel
    var body: some View {
        Section("Details") {
            TextField("Description * (e.g., Dinner, Cab)", text: $viewModel.description)
                .textInputAutocapitalization(.sentences)
            TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6).textInputAutocapitalization(.sentences)
        }
    }
}

private struct GroupEditorPaidBySection: View {
    @Bindable var viewModel: GroupTransactionEditorViewModel
    var body: some View {
        Section("Paid By") {
            ForEach(viewModel.members) { member in
                let isSelected = viewModel.paidByUserId == member.id
                Button { viewModel.paidByUserId = member.id } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.displayName(for: member)).foregroundStyle(.primary)
                            Text(member.email).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark").font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                        }
                    }
                }
                .listRowBackground(isSelected ? AppColors.chipBackground : AppColors.surface)
            }
        }
    }
}

private struct GroupEditorSplitMembersSection: View {
    @Bindable var viewModel: GroupTransactionEditorViewModel
    var body: some View {
        Section("Split Between") {
            ForEach(viewModel.members) { member in
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

// MARK: - Split section for group editor

struct SplitSectionGroup: View {
    @Bindable var viewModel: GroupTransactionEditorViewModel

    var body: some View {
        Section("Split") {
            Picker("Split Type", selection: $viewModel.splitType) {
                ForEach(SplitType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            if viewModel.splitType == .equal && !viewModel.selectedMembers.isEmpty {
                HStack {
                    Text("Each person pays").foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.equalShareText).fontWeight(.semibold).foregroundStyle(.primary)
                }
                .font(.subheadline)
            }
        }

        if viewModel.splitType == .custom && !viewModel.selectedMembers.isEmpty {
            Section {
                HStack {
                    Text("Total assigned")
                    Spacer()
                    Text(CurrencyFormatter.format(viewModel.customSplitTotal, showDecimals: true))
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.splitMatchesTotal ? AppColors.income : AppColors.expense)
                }
                if !viewModel.splitMatchesTotal {
                    let diff = (Double(viewModel.amount) ?? 0) - viewModel.customSplitTotal
                    HStack {
                        Text(diff > 0 ? "Remaining" : "Over by").foregroundStyle(.secondary)
                        Spacer()
                        Text(CurrencyFormatter.format(abs(diff), showDecimals: true)).foregroundStyle(AppColors.warning)
                    }
                    .font(.caption)
                }
            } footer: {
                if !viewModel.splitMatchesTotal {
                    Text("Custom split amounts must equal the total.").foregroundStyle(AppColors.expense)
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
    GroupTransactionEditorView(
        mode: .create(group: group, members: [alice, bob], currentUserId: aliceId, onAdd: { _ in }),
        groupService: GroupService.shared
    )
    .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
