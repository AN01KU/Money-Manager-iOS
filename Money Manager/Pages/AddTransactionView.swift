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
            if viewModel.isShared {
                sharedForm
            } else {
                personalScrollView
            }
        }
    }

    // MARK: - Personal (card-based ScrollView)

    private var personalScrollView: some View {
        ScrollView {
            VStack(spacing: AppConstants.UI.spacing20) {
                amountCard
                typeSegment
                dateCard
                detailsCard
                recurringCard
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
        .alert("Update Recurring Transaction?", isPresented: $viewModel.showRecurringAmountAlert) {
            Button("Update Recurring Too") { viewModel.saveAlsoUpdatingRecurring { saveSuccess = true; dismiss() } }
            Button("Just This Transaction") { viewModel.saveThisTransactionOnly(); saveSuccess = true; dismiss() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You changed the amount. Do you want to update the recurring transaction template as well?")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.showError) { _, show in if show { errorTriggered += 1 } }
        .sensoryFeedback(.error, trigger: errorTriggered)
        .task { viewModel.modelContext = modelContext; viewModel.customCategories = customCategories }
        .onChange(of: customCategories) { _, newValue in viewModel.customCategories = newValue }
    }

    // MARK: - Amount + Category card

    @State private var categoryTapped = 0
    @State private var amount10Tapped = 0
    @State private var amount100Tapped = 0
    @State private var amountPlus10Tapped = 0
    @State private var amountPlus100Tapped = 0

    private var amountCard: some View {
        TxnCard {
            VStack(alignment: .leading, spacing: AppConstants.UI.spacing12) {
                Text("Amount *")
                    .font(AppTypography.subhead)
                    .foregroundStyle(AppColors.label2)

                TextField("0.00", text: $viewModel.amount)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(viewModel.amount.isEmpty ? AppColors.label3 : AppColors.label)
                    .disabled(viewModel.isEditingShared)
                    .accessibilityIdentifier("amount-field")

                HStack(spacing: AppConstants.UI.spacingSM) {
                    QuickAmountButton(amount: -10) { amount10Tapped += 1; adjustAmount(by: -10) }
                        .sensoryFeedback(.impact(weight: .light), trigger: amount10Tapped)
                    QuickAmountButton(amount: -100) { amount100Tapped += 1; adjustAmount(by: -100) }
                        .sensoryFeedback(.impact(weight: .light), trigger: amount100Tapped)
                    QuickAmountButton(amount: 10) { amountPlus10Tapped += 1; adjustAmount(by: 10) }
                        .sensoryFeedback(.impact(weight: .light), trigger: amountPlus10Tapped)
                    QuickAmountButton(amount: 100) { amountPlus100Tapped += 1; adjustAmount(by: 100) }
                        .sensoryFeedback(.impact(weight: .light), trigger: amountPlus100Tapped)
                }

                Divider()

                VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
                    Text("Category *")
                        .font(AppTypography.subhead)
                        .foregroundStyle(AppColors.label2)

                    Button {
                        categoryTapped += 1
                        viewModel.showCategoryPicker = true
                    } label: {
                        HStack(spacing: AppConstants.UI.spacingSM) {
                            if let custom = customCategories.first(where: { $0.name == viewModel.selectedCategory && !$0.isHidden }) {
                                AppIcon(name: custom.icon, size: 20, color: Color(hex: custom.color))
                                Text(viewModel.selectedCategory)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.label)
                            } else if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == viewModel.selectedCategory }) {
                                AppIcon(name: predefined.icon, size: 20, color: predefined.color)
                                Text(viewModel.selectedCategory)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.label)
                            } else {
                                Text("Select Category")
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.primary)
                            }
                            Spacer()
                            AppIcon(name: AppIcons.UI.chevron, size: 14, color: AppColors.primary)
                                .rotationEffect(.degrees(90))
                        }
                        .padding(AppConstants.UI.spacing12)
                        .background(AppColors.primaryBg)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.radius10))
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: categoryTapped)
                    .accessibilityIdentifier("category-picker-button")
                }
            }
        }
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

    // MARK: - Date card

    @State private var todayTapped = 0
    @State private var yesterdayTapped = 0

    private var dateCard: some View {
        TxnCard {
            VStack(alignment: .leading, spacing: AppConstants.UI.spacing12) {
                HStack {
                    Text(viewModel.isRecurring ? "Start Date *" : "Date *")
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                    Spacer()
                    DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }

                HStack(spacing: AppConstants.UI.spacingSM) {
                    QuickDateButton(label: "Today") { todayTapped += 1; viewModel.selectedDate = Date() }
                        .sensoryFeedback(.impact(weight: .light), trigger: todayTapped)
                    QuickDateButton(label: "Yesterday") {
                        yesterdayTapped += 1
                        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: yesterdayTapped)
                }

                if !viewModel.isRecurring {
                    Divider()
                    Toggle(isOn: $viewModel.hasTime) {
                        Text("Include Time")
                            .font(AppTypography.body)
                    }
                    .tint(AppColors.accent)

                    if viewModel.hasTime {
                        DatePicker("", selection: $viewModel.selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                }
            }
        }
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

    // MARK: - Recurring card

    private var recurringCard: some View {
        TxnCard {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: AppConstants.UI.spacingSM) {
                        AppIcon(name: AppIcons.UI.recurring, size: 20, color: AppColors.accent)
                        Text("Recurring")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.accent)
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.isRecurring)
                        .labelsHidden()
                        .tint(AppColors.accent)
                }

                if viewModel.isRecurring {
                    Divider().padding(.vertical, AppConstants.UI.spacing12)

                    TxnPickerRow(label: "Frequency") {
                        Picker("", selection: $viewModel.recurringFrequency) {
                            ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                                Text(freq.rawValue.capitalized).tag(freq)
                            }
                        }
                        .tint(AppColors.accent)
                    }

                    if viewModel.recurringFrequency == .monthly {
                        Divider().padding(.vertical, AppConstants.UI.spacing12)
                        TxnPickerRow(label: "Day of Month") {
                            Picker("", selection: $viewModel.recurringDayOfMonth) {
                                ForEach(1...28, id: \.self) { day in
                                    Text("\(day)").tag(day)
                                }
                            }
                            .tint(AppColors.accent)
                        }
                    }

                    Divider().padding(.vertical, AppConstants.UI.spacing12)

                    HStack {
                        Text("Set End Date")
                            .font(AppTypography.body)
                        Spacer()
                        Toggle("", isOn: $viewModel.recurringHasEndDate)
                            .labelsHidden()
                            .tint(AppColors.accent)
                    }

                    if viewModel.recurringHasEndDate {
                        Divider().padding(.vertical, AppConstants.UI.spacing12)
                        DatePicker("End Date", selection: $viewModel.recurringEndDate,
                                   in: viewModel.selectedDate..., displayedComponents: .date)
                            .font(AppTypography.body)
                    }
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var personalToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
                .accessibilityIdentifier("cancel-button")
        }
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.isSaving {
                ProgressView()
            } else {
                Button("Save") { viewModel.save { saveSuccess = true; dismiss() } }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid)
                    .accessibilityIdentifier("save-button")
            }
        }
    }

    // MARK: - Helpers

    private func adjustAmount(by delta: Int) {
        let current = Double(viewModel.amount) ?? 0
        let result = max(0, current + Double(delta))
        viewModel.amount = result.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(result))
            : String(result)
    }

    // MARK: - Shared form (BAU — unchanged layout)

    private var sharedForm: some View {
        Form {
            AddTransactionAmountSection(viewModel: viewModel, customCategories: customCategories)

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

            AddTransactionSharedDescriptionSection(viewModel: viewModel)
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
                    Button("Save") { viewModel.save { saveSuccess = true; dismiss() } }
                        .fontWeight(.semibold)
                        .disabled(!viewModel.isValid)
                        .accessibilityIdentifier("save-button")
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.showError) { _, show in if show { errorTriggered += 1 } }
        .sensoryFeedback(.error, trigger: errorTriggered)
        .task { viewModel.modelContext = modelContext; viewModel.customCategories = customCategories }
        .onChange(of: customCategories) { _, newValue in viewModel.customCategories = newValue }
    }
}

// MARK: - Reusable card wrapper

private struct TxnCard<Content: View>: View {
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

private struct TxnPickerRow<Picker: View>: View {
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
    let customCategories: [CustomCategory]
    @State private var categoryTapped = 0

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
                    .listRowBackground(isSelected ? Color(.systemGray5) : Color(.systemBackground))
                }
            }
        }
    }
}

private struct AddTransactionSplitSection: View {
    @Bindable var viewModel: AddTransactionViewModel
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
                    .listRowBackground(isIncluded ? Color(.systemGray5) : Color(.systemBackground))
                }
            }
        }
    }
}

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
