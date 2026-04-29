import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

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
            Form {
                AddTransactionAmountSection(viewModel: viewModel, customCategories: customCategories)

                if viewModel.isShared {
                    AddTransactionSharedDescriptionSection(viewModel: viewModel)
                    if viewModel.isEditingShared {
                        Section {
                            Label("Amount and split cannot be changed after creation.", systemImage: "lock.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        AddTransactionPaidBySection(viewModel: viewModel)
                        AddTransactionSplitSection(viewModel: viewModel)
                        AddTransactionSplitMembersSection(viewModel: viewModel)
                        if viewModel.splitType == .custom && !viewModel.selectedMembers.isEmpty {
                            AddTransactionSplitSummarySection(viewModel: viewModel)
                        }
                    }
                } else {
                    AddTransactionTypeSection(viewModel: viewModel)
                    AddTransactionDateTimeSection(viewModel: viewModel)
                    AddTransactionDetailsSection(viewModel: viewModel)
                    AddTransactionRecurringSection(viewModel: viewModel)
                }
            }
            .dismissKeyboardOnScroll()
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier(viewModel.navigationTitleIdentifier)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancel-button")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            viewModel.save { saveSuccess = true; dismiss() }
                        }
                        .fontWeight(.semibold)
                        .disabled(!viewModel.isValid)
                        .accessibilityIdentifier("save-button")
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.showCategoryPicker) {
                CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
            }
            .alert("Update Recurring Transaction?", isPresented: $viewModel.showRecurringAmountAlert) {
                Button("Update Recurring Too") {
                    viewModel.saveAlsoUpdatingRecurring { saveSuccess = true; dismiss() }
                }
                Button("Just This Transaction") {
                    viewModel.saveThisTransactionOnly()
                    saveSuccess = true
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You changed the amount. Do you want to update the recurring transaction template as well?")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onChange(of: viewModel.showError) { _, show in
                if show { errorTriggered += 1 }
            }
            .sensoryFeedback(.error, trigger: errorTriggered)
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

// MARK: - Shared: Amount + Category (same as personal)

private struct AddTransactionAmountSection: View {
    @Bindable var viewModel: AddTransactionViewModel
    let customCategories: [CustomCategory]

    @State private var amount100Tapped = 0
    @State private var amount500Tapped = 0
    @State private var amount1000Tapped = 0
    @State private var categoryTapped = 0

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount *")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("0.00", text: $viewModel.amount)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .disabled(viewModel.isEditingShared)
                    .foregroundStyle(viewModel.isEditingShared ? .secondary : .primary)
                    .accessibilityIdentifier("amount-field")

                if !viewModel.isEditingShared {
                    HStack(spacing: 12) {
                        QuickAmountButton(amount: 100) { amount100Tapped += 1; viewModel.amount = "100" }
                            .sensoryFeedback(.impact(weight: .light), trigger: amount100Tapped)
                        QuickAmountButton(amount: 500) { amount500Tapped += 1; viewModel.amount = "500" }
                            .sensoryFeedback(.impact(weight: .light), trigger: amount500Tapped)
                        QuickAmountButton(amount: 1000) { amount1000Tapped += 1; viewModel.amount = "1000" }
                            .sensoryFeedback(.impact(weight: .light), trigger: amount1000Tapped)
                    }
                }
            }
            .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Category *")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    categoryTapped += 1
                    viewModel.showCategoryPicker = true
                } label: {
                    HStack {
                        if let custom = customCategories.first(where: { $0.name == viewModel.selectedCategory && !$0.isHidden }) {
                            AppIcon(name: custom.icon, size: 20, color: Color(hex: custom.color))
                            Text(viewModel.selectedCategory)
                        } else if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == viewModel.selectedCategory }) {
                            AppIcon(name: predefined.icon, size: 20, color: predefined.color)
                            Text(viewModel.selectedCategory)
                        } else {
                            Text(viewModel.selectedCategory.isEmpty ? "Select Category" : viewModel.selectedCategory)
                                .foregroundStyle(viewModel.selectedCategory.isEmpty ? .secondary : .primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.down").foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 8))
                }
                .sensoryFeedback(.impact(weight: .light), trigger: categoryTapped)
                .accessibilityIdentifier("category-picker-button")
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Personal: Transaction Type

private struct AddTransactionTypeSection: View {
    @Bindable var viewModel: AddTransactionViewModel

    var body: some View {
        Section {
            Picker("Type", selection: $viewModel.transactionType) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Personal: Date + Time

private struct AddTransactionDateTimeSection: View {
    @Bindable var viewModel: AddTransactionViewModel

    @State private var todayTapped = 0
    @State private var yesterdayTapped = 0

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(viewModel.isRecurring ? "Start Date *" : "Date *")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }

                HStack(spacing: 12) {
                    QuickDateButton(label: "Today") { todayTapped += 1; viewModel.selectedDate = Date() }
                        .sensoryFeedback(.impact(weight: .light), trigger: todayTapped)
                    QuickDateButton(label: "Yesterday") {
                        yesterdayTapped += 1
                        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: yesterdayTapped)
                }
            }
            .padding(.vertical, 8)

            if !viewModel.isRecurring {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Include Time", isOn: $viewModel.hasTime)
                    if viewModel.hasTime {
                        DatePicker("Select Time", selection: $viewModel.selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Personal: Details

private struct AddTransactionDetailsSection: View {
    @Bindable var viewModel: AddTransactionViewModel

    var body: some View {
        Section("Details") {
            TextField(
                viewModel.isRecurring ? "Name * (e.g., Rent, Netflix)" : "Description (e.g., Lunch at cafe)",
                text: $viewModel.description
            )
            .textInputAutocapitalization(.sentences)
            .accessibilityIdentifier("description-field")
            TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
                .textInputAutocapitalization(.sentences)
        }
    }
}

// MARK: - Personal: Recurring

private struct AddTransactionRecurringSection: View {
    @Bindable var viewModel: AddTransactionViewModel

    var body: some View {
        Section {
            Toggle(isOn: $viewModel.isRecurring) {
                Label("Recurring", systemImage: "arrow.clockwise.circle.fill")
                    .foregroundStyle(AppColors.accent)
            }

            if viewModel.isRecurring {
                Picker("Frequency", selection: $viewModel.recurringFrequency) {
                    ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue.capitalized).tag(freq)
                    }
                }

                if viewModel.recurringFrequency == .monthly {
                    Picker("Day of Month", selection: $viewModel.recurringDayOfMonth) {
                        ForEach(1...28, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                }

                Toggle("Set End Date", isOn: $viewModel.recurringHasEndDate)

                if viewModel.recurringHasEndDate {
                    DatePicker("End Date", selection: $viewModel.recurringEndDate, in: viewModel.selectedDate..., displayedComponents: .date)
                }
            }
        }
    }
}

// MARK: - Shared: Description (required)

private struct AddTransactionSharedDescriptionSection: View {
    @Bindable var viewModel: AddTransactionViewModel

    var body: some View {
        Section("Details") {
            TextField("Description * (e.g., Dinner, Cab)", text: $viewModel.description)
                .textInputAutocapitalization(.sentences)
            TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
                .textInputAutocapitalization(.sentences)
        }
    }
}

// MARK: - Shared: Paid By

private struct AddTransactionPaidBySection: View {
    @Bindable var viewModel: AddTransactionViewModel

    var body: some View {
        Section("Paid By") {
            if case .shared(_, let members, _, _, _) = viewModel.mode {
                ForEach(members) { member in
                    let isSelected = viewModel.paidByUserId == member.id
                    Button {
                        viewModel.paidByUserId = member.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.displayName(for: member))
                                    .foregroundStyle(.primary)
                                Text(member.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .listRowBackground(isSelected ? Color(.systemGray5) : Color(.systemBackground))
                }
            }
        }
    }
}

// MARK: - Shared: Split Type

private struct AddTransactionSplitSection: View {
    @Bindable var viewModel: AddTransactionViewModel

    var body: some View {
        Section("Split") {
            Picker("Split Type", selection: $viewModel.splitType) {
                ForEach(SplitType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.splitType == .equal && !viewModel.selectedMembers.isEmpty {
                HStack {
                    Text("Each person pays")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.equalShareText)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .font(.subheadline)
            }
        }
    }
}

// MARK: - Shared: Member Selection + Custom Amounts

private struct AddTransactionSplitMembersSection: View {
    @Bindable var viewModel: AddTransactionViewModel

    var body: some View {
        Section("Split Between") {
            if case .shared(_, let members, _, _, _) = viewModel.mode {
                ForEach(members) { member in
                    let isIncluded = viewModel.selectedMembers.contains(member.id)
                    Button {
                        viewModel.toggleMember(member.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.displayName(for: member))
                                    .foregroundStyle(.primary)
                                Text(member.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if viewModel.splitType == .custom && isIncluded {
                                TextField("0.00", text: viewModel.customAmountBinding(for: member.id))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                            } else if viewModel.splitType == .equal && isIncluded {
                                Text(viewModel.equalShareText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if isIncluded {
                                Image(systemName: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                    .listRowBackground(isIncluded ? Color(.systemGray5) : Color(.systemBackground))
                }
            }
        }
    }
}

// MARK: - Shared: Custom Split Summary

private struct AddTransactionSplitSummarySection: View {
    @Bindable var viewModel: AddTransactionViewModel

    var body: some View {
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
                    Text(diff > 0 ? "Remaining" : "Over by")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.format(abs(diff), showDecimals: true))
                        .foregroundStyle(AppColors.warning)
                }
                .font(.caption)
            }
        } footer: {
            if !viewModel.splitMatchesTotal {
                Text("Custom split amounts must equal the total.")
                    .foregroundStyle(AppColors.expense)
            }
        }
    }
}

// MARK: - Previews

#Preview("New Transaction") {
    AddTransactionView()
        .modelContainer(for: [Transaction.self, CustomCategory.self], inMemory: true)
}

#Preview("Edit Transaction") {
    let transaction = Transaction(amount: 450, category: "Food & Dining", date: Date(), transactionDescription: "Lunch at cafe", notes: "With colleagues")
    AddTransactionView(transactionToEdit: transaction)
        .modelContainer(for: [Transaction.self, CustomCategory.self], inMemory: true)
}

#Preview("Group Transaction") {
    let groupId = UUID()
    let alice = APIGroupMember(id: UUID(), email: "alice@example.com", username: "alice", joinedAt: Date())
            let bob   = APIGroupMember(id: UUID(), email: "bob@example.com",   username: "bob",   joinedAt: Date())
    let group = APIGroupWithDetails(id: groupId, name: "Weekend Trip", createdBy: alice.id, createdAt: Date(), members: [alice, bob], balances: [])
    AddTransactionView(mode: .shared(group: group, members: [alice, bob], onAdd: { _ in }), groupService: GroupService.shared)
        .modelContainer(for: [Transaction.self, CustomCategory.self], inMemory: true)
}
