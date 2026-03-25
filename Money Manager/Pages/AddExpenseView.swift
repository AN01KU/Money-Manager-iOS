import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    @State private var viewModel: AddExpenseViewModel
    @State private var amount100Tapped = false
    @State private var amount500Tapped = false
    @State private var amount1000Tapped = false
    @State private var categoryTapped = false
    @State private var todayTapped = false
    @State private var saveSuccess = false
    @State private var errorTriggered = false

    init(mode: AddExpenseMode = .personal()) {
        _viewModel = State(wrappedValue: AddExpenseViewModel(mode: mode))
    }

    init(expenseToEdit: Expense) {
        _viewModel = State(wrappedValue: AddExpenseViewModel(mode: .personal(editing: expenseToEdit)))
    }

    var body: some View {
        NavigationStack {
            Form {
                amountSection

                if viewModel.isShared {
                    sharedDescriptionSection
                    paidBySection
                    splitSection
                    splitMembersSection
                    if viewModel.splitType == .custom && !viewModel.selectedMembers.isEmpty {
                        splitSummarySection
                    }
                } else {
                    dateTimeSection
                    detailsSection
                    Section {
                        Button {
                            viewModel.showRecurringSheet = true
                        } label: {
                            Label("Set Up as Recurring", systemImage: "arrow.clockwise.circle.fill")
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
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
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCategoryPicker) {
                CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
            }
            .sheet(isPresented: $viewModel.showRecurringSheet) {
                AddRecurringExpenseSheet(prefillAmount: viewModel.amount, prefillCategory: viewModel.selectedCategory)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onChange(of: viewModel.showError) { _, show in
                if show { errorTriggered = true }
            }
            .sensoryFeedback(.error, trigger: errorTriggered)
            .onChange(of: errorTriggered) { _, newValue in
                if newValue { errorTriggered = false }
            }
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
        }
    }

    // MARK: - Shared: Amount + Category (same as personal)

    private var amountSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount *")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("0.00", text: $viewModel.amount)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack(spacing: 12) {
                    QuickAmountButton(amount: 100) { amount100Tapped = true; viewModel.amount = "100" }
                        .sensoryFeedback(.impact(weight: .light), trigger: amount100Tapped)
                        .onChange(of: amount100Tapped) { _, v in if v { amount100Tapped = false } }
                    QuickAmountButton(amount: 500) { amount500Tapped = true; viewModel.amount = "500" }
                        .sensoryFeedback(.impact(weight: .light), trigger: amount500Tapped)
                        .onChange(of: amount500Tapped) { _, v in if v { amount500Tapped = false } }
                    QuickAmountButton(amount: 1000) { amount1000Tapped = true; viewModel.amount = "1000" }
                        .sensoryFeedback(.impact(weight: .light), trigger: amount1000Tapped)
                        .onChange(of: amount1000Tapped) { _, v in if v { amount1000Tapped = false } }
                }
            }
            .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Category *")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    categoryTapped = true
                    viewModel.showCategoryPicker = true
                } label: {
                    HStack {
                        if let custom = customCategories.first(where: { $0.name == viewModel.selectedCategory && !$0.isHidden }) {
                            Image(systemName: custom.icon).foregroundStyle(Color(hex: custom.color))
                            Text(viewModel.selectedCategory)
                        } else if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == viewModel.selectedCategory }) {
                            Image(systemName: predefined.icon).foregroundStyle(predefined.color)
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
                .onChange(of: categoryTapped) { _, v in if v { categoryTapped = false } }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Personal: Date + Time

    private var dateTimeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Date *")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                DatePicker("Select Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()

                HStack(spacing: 12) {
                    QuickDateButton(label: "Today") { todayTapped = true; viewModel.selectedDate = Date() }
                        .sensoryFeedback(.impact(weight: .light), trigger: todayTapped)
                        .onChange(of: todayTapped) { _, v in if v { todayTapped = false } }
                    QuickDateButton(label: "Yesterday") {
                        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                    }
                }
            }
            .padding(.vertical, 8)

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

    // MARK: - Personal: Details

    private var detailsSection: some View {
        Section("Details") {
            TextField("Description (e.g., Lunch at cafe)", text: $viewModel.description)
                .textInputAutocapitalization(.sentences)
            TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
                .textInputAutocapitalization(.sentences)
        }
    }

    // MARK: - Shared: Description (required)

    private var sharedDescriptionSection: some View {
        Section("Details") {
            TextField("Description * (e.g., Dinner, Cab)", text: $viewModel.description)
                .textInputAutocapitalization(.sentences)
            TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
                .textInputAutocapitalization(.sentences)
        }
    }

    // MARK: - Shared: Paid By

    private var paidBySection: some View {
        Section("Paid By") {
            if case .shared(_, let members, _) = viewModel.mode {
                ForEach(members) { member in
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
                            Image(systemName: viewModel.paidByUserId == member.id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.paidByUserId == member.id ? AppColors.accent : .secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shared: Split Type

    private var splitSection: some View {
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
                        .foregroundStyle(AppColors.accent)
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - Shared: Member Selection + Custom Amounts

    private var splitMembersSection: some View {
        Section("Split Between") {
            if case .shared(_, let members, _) = viewModel.mode {
                ForEach(members) { member in
                    HStack {
                        Button {
                            viewModel.toggleMember(member.id)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: viewModel.selectedMembers.contains(member.id) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(viewModel.selectedMembers.contains(member.id) ? AppColors.accent : .secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(viewModel.displayName(for: member))
                                        .foregroundStyle(.primary)
                                    Text(member.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Spacer()

                        if viewModel.splitType == .custom && viewModel.selectedMembers.contains(member.id) {
                            TextField("0.00", text: viewModel.customAmountBinding(for: member.id))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .fontWeight(.medium)
                        } else if viewModel.splitType == .equal && viewModel.selectedMembers.contains(member.id) {
                            Text(viewModel.equalShareText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shared: Custom Split Summary

    private var splitSummarySection: some View {
        Section {
            HStack {
                Text("Total assigned")
                Spacer()
                Text(CurrencyFormatter.format(viewModel.customSplitTotal, showDecimals: true))
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.splitMatchesTotal ? AppColors.positive : AppColors.expense)
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

#Preview("New Expense") {
    AddExpenseView()
        .modelContainer(for: [Expense.self, CustomCategory.self], inMemory: true)
}

#Preview("Edit Expense") {
    let expense = Expense(amount: 450, category: "Food & Dining", date: Date(), expenseDescription: "Lunch at cafe", notes: "With colleagues")
    AddExpenseView(expenseToEdit: expense)
        .modelContainer(for: [Expense.self, CustomCategory.self], inMemory: true)
}

#Preview("Group Expense") {
    let groupId = UUID()
    let alice = APIGroupMember(id: UUID(), email: "alice@example.com", username: "alice", createdAt: Date())
    let bob   = APIGroupMember(id: UUID(), email: "bob@example.com",   username: "bob",   createdAt: Date())
    let group = APIGroupWithDetails(id: groupId, name: "Weekend Trip", created_by: alice.id, created_at: Date(), members: [alice, bob], balances: [])
    AddExpenseView(mode: .shared(group: group, members: [alice, bob]) { _ in })
        .modelContainer(for: [Expense.self, CustomCategory.self], inMemory: true)
}
