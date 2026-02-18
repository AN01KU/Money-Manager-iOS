import SwiftUI
import SwiftData

// MARK: - Mode

enum AddExpenseMode {
    case personal(editing: Expense? = nil)
    case shared(group: SplitGroup, members: [APIUser], onAdd: (SharedExpense) -> Void)
}

// MARK: - View

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let mode: AddExpenseMode
    
    // Shared state
    @State private var amount = ""
    @State private var selectedCategory = ""
    @State private var description = ""
    @State private var notes = ""
    @State private var showCategoryPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    // Personal-only state
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var hasTime = true
    @State private var isRecurring = false
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    
    // Shared-only state
    @State private var paidByUserId: UUID?
    @State private var splitType: SplitType = .equal
    @State private var selectedMembers: Set<UUID> = []
    @State private var customAmounts: [UUID: String] = [:]
    
    enum SplitType: String, CaseIterable {
        case equal = "Equal"
        case custom = "Custom"
    }
    
    init(mode: AddExpenseMode = .personal()) {
        self.mode = mode
    }
    
    init(expenseToEdit: Expense) {
        self.mode = .personal(editing: expenseToEdit)
    }
    
    private var isShared: Bool {
        if case .shared = mode { return true }
        return false
    }
    
    private var navigationTitle: String {
        switch mode {
        case .personal(let editing):
            return editing != nil ? "Edit Expense" : "Add Expense"
        case .shared:
            return "Add Shared Expense"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                mainSection
                
                if isShared {
                    paidBySection
                    splitSection
                    splitMembersSection
                    if splitType == .custom && !selectedMembers.isEmpty {
                        splitSummarySection
                    }
                } else {
                    dateTimeSection
                    detailsSection
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                            .fontWeight(.semibold)
                            .disabled(!isValid)
                    }
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                if isShared {
                    sharedCategoryPicker
                } else {
                    CategoryPickerView(selectedCategory: $selectedCategory)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate)
            }
            .sheet(isPresented: $showTimePicker) {
                TimePickerSheet(selectedTime: $selectedTime)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear { onAppearSetup() }
        }
    }
    
    // MARK: - Main Section (Amount, Category, Description for shared)
    
    private var mainSection: some View {
        Section {
            if isShared {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description *")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Dinner, Cab, Groceries", text: $description)
                        .textInputAutocapitalization(.sentences)
                }
                .padding(.vertical, 4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount *")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    QuickAmountButton(amount: 100) { amount = "100" }
                    QuickAmountButton(amount: 500) { amount = "500" }
                    QuickAmountButton(amount: 1000) { amount = "1000" }
                }
            }
            .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Category *")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: { showCategoryPicker = true }) {
                    HStack {
                        if let category = PredefinedCategory.allCases.first(where: { $0.rawValue == selectedCategory }) {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            Text(selectedCategory)
                        } else {
                            Text(selectedCategory.isEmpty ? "Select Category" : selectedCategory)
                                .foregroundColor(selectedCategory.isEmpty ? .secondary : .primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Personal: Date/Time
    
    private var dateTimeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Date *")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: { showDatePicker = true }) {
                    HStack {
                        Text(formatDate(selectedDate))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                HStack(spacing: 12) {
                    QuickDateButton(label: "Today") { selectedDate = Date() }
                    QuickDateButton(label: "Yesterday") {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                    }
                }
            }
            .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Include Time", isOn: $hasTime)
                
                if hasTime {
                    Button(action: { showTimePicker = true }) {
                        HStack {
                            Text(formatTime(selectedTime))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Personal: Details
    
    private var detailsSection: some View {
        Group {
            Section("Details") {
                TextField("Description (e.g., Lunch at cafe)", text: $description)
                    .textInputAutocapitalization(.sentences)
                
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.sentences)
            }
            
            Section {
                Toggle("Make this recurring?", isOn: $isRecurring)
            }
        }
    }
    
    // MARK: - Shared: Paid By
    
    private var paidBySection: some View {
        Section("Paid By") {
            if case .shared(_, let members, _) = mode {
                ForEach(members) { member in
                    Button { paidByUserId = member.id } label: {
                        HStack {
                            Text(displayName(for: member))
                                .foregroundColor(.primary)
                            Text(member.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: paidByUserId == member.id ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(paidByUserId == member.id ? .teal : .secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Shared: Split Type
    
    private var splitSection: some View {
        Section {
            Picker("Split Type", selection: $splitType) {
                ForEach(SplitType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Split Between")
        }
    }
    
    // MARK: - Shared: Members
    
    private var splitMembersSection: some View {
        Section {
            if case .shared(_, let members, _) = mode {
                ForEach(members) { member in
                    HStack {
                        Button { toggleMember(member.id) } label: {
                            HStack {
                                Image(systemName: selectedMembers.contains(member.id) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(selectedMembers.contains(member.id) ? .teal : .secondary)
                                Text(displayName(for: member))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                        
                        if splitType == .equal {
                            if selectedMembers.contains(member.id) {
                                Text(equalShareText)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            if selectedMembers.contains(member.id) {
                                TextField("0.00", text: binding(for: member.id))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Shared: Split Summary
    
    private var splitSummarySection: some View {
        Section {
            HStack {
                Text("Total split")
                    .foregroundColor(.secondary)
                Spacer()
                Text(CurrencyFormatter.format(customSplitTotal, showDecimals: true))
                    .fontWeight(.semibold)
                    .foregroundColor(splitMatchesTotal ? .green : .red)
            }
            
            if let total = Double(amount), total > 0 {
                HStack {
                    Text("Remaining")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.format(total - customSplitTotal, showDecimals: true))
                        .fontWeight(.semibold)
                        .foregroundColor(splitMatchesTotal ? .green : .orange)
                }
            }
        }
    }
    
    // MARK: - Shared: Category Picker (inline)
    
    private var sharedCategoryPicker: some View {
        NavigationStack {
            List {
                ForEach(PredefinedCategory.allCases) { category in
                    Button {
                        selectedCategory = category.rawValue
                        showCategoryPicker = false
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                                .frame(width: 30)
                            Text(category.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCategory == category.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.teal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showCategoryPicker = false }
                }
            }
        }
    }
    
    // MARK: - Validation
    
    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0,
              !selectedCategory.isEmpty else { return false }
        
        switch mode {
        case .personal:
            return true
        case .shared:
            guard !description.trimmingCharacters(in: .whitespaces).isEmpty,
                  paidByUserId != nil,
                  !selectedMembers.isEmpty else { return false }
            if splitType == .custom { return splitMatchesTotal }
            return true
        }
    }
    
    // MARK: - Split Helpers
    
    private var equalShareText: String {
        guard let total = Double(amount), total > 0, !selectedMembers.isEmpty else { return "₹0" }
        return CurrencyFormatter.format(total / Double(selectedMembers.count), showDecimals: true)
    }
    
    private var customSplitTotal: Double {
        selectedMembers.compactMap { Double(customAmounts[$0] ?? "") }.reduce(0, +)
    }
    
    private var splitMatchesTotal: Bool {
        guard let total = Double(amount) else { return false }
        return abs(customSplitTotal - total) < 0.01
    }
    
    private func binding(for userId: UUID) -> Binding<String> {
        Binding(
            get: { customAmounts[userId] ?? "" },
            set: { customAmounts[userId] = $0 }
        )
    }
    
    private func toggleMember(_ id: UUID) {
        if selectedMembers.contains(id) {
            selectedMembers.remove(id)
        } else {
            selectedMembers.insert(id)
        }
    }
    
    private func displayName(for member: APIUser) -> String {
        member.email.components(separatedBy: "@").first?.capitalized ?? member.email
    }
    
    private func buildSplits() -> [ExpenseSplit] {
        guard let total = Double(amount) else { return [] }
        let sortedMembers = selectedMembers.sorted { $0.uuidString < $1.uuidString }
        
        if splitType == .equal {
            let share = total / Double(sortedMembers.count)
            let rounded = (share * 100).rounded() / 100
            var splits: [ExpenseSplit] = []
            var remaining = total
            
            for (i, userId) in sortedMembers.enumerated() {
                if i == sortedMembers.count - 1 {
                    splits.append(ExpenseSplit(userId: userId, amount: String(format: "%.2f", remaining)))
                } else {
                    splits.append(ExpenseSplit(userId: userId, amount: String(format: "%.2f", rounded)))
                    remaining -= rounded
                }
            }
            return splits
        } else {
            return sortedMembers.compactMap { userId in
                guard let amt = Double(customAmounts[userId] ?? ""), amt > 0 else { return nil }
                return ExpenseSplit(userId: userId, amount: String(format: "%.2f", amt))
            }
        }
    }
    
    // MARK: - Setup
    
    private func onAppearSetup() {
        switch mode {
        case .personal(let editing):
            if let expense = editing {
                amount = String(format: "%.2f", expense.amount)
                selectedCategory = expense.category
                selectedDate = expense.date
                selectedTime = expense.time ?? Date()
                hasTime = expense.time != nil
                description = expense.expenseDescription ?? ""
                notes = expense.notes ?? ""
            }
        case .shared(_, let members, _):
            paidByUserId = useTestData ? TestData.currentUser.id : APIService.shared.currentUser?.id
            selectedMembers = Set(members.map(\.id))
        }
    }
    
    // MARK: - Save
    
    private func save() {
        switch mode {
        case .personal:
            savePersonalExpense()
        case .shared:
            saveSharedExpense()
        }
    }
    
    private func savePersonalExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Amount must be greater than 0"
            showError = true
            return
        }
        
        isSaving = true
        let calendar = Calendar.current
        var expenseDate = calendar.startOfDay(for: selectedDate)
        
        if hasTime {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
            expenseDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                        minute: timeComponents.minute ?? 0,
                                        second: 0,
                                        of: selectedDate) ?? selectedDate
        }
        
        Task {
            do {
                if !useTestData {
                    let request = CreatePersonalExpenseRequest(
                        categoryId: nil,
                        amount: String(format: "%.2f", amountValue),
                        description: description.isEmpty ? nil : description,
                        notes: notes.isEmpty ? nil : notes,
                        expenseDate: ISO8601DateFormatter().string(from: expenseDate)
                    )
                    _ = try await APIService.shared.createPersonalExpense(request)
                }
                
                let expense = Expense(
                    amount: amountValue,
                    category: selectedCategory,
                    date: expenseDate,
                    time: hasTime ? selectedTime : nil,
                    expenseDescription: description.isEmpty ? nil : description,
                    notes: notes.isEmpty ? nil : notes
                )
                modelContext.insert(expense)
                try modelContext.save()
                
                isSaving = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isSaving = false
            }
        }
    }
    
    private func saveSharedExpense() {
        guard case .shared(let group, _, let onAdd) = mode,
              let paidBy = paidByUserId else { return }
        
        let splits = buildSplits()
        isSaving = true
        
        Task {
            if useTestData {
                try? await Task.sleep(for: .milliseconds(300))
                let expense = SharedExpense(
                    id: UUID(),
                    groupId: group.id,
                    description: description.trimmingCharacters(in: .whitespaces),
                    category: selectedCategory,
                    totalAmount: String(format: "%.2f", Double(amount) ?? 0),
                    paidBy: paidBy,
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    splits: splits
                )
                onAdd(expense)
                saveLocalGroupShare(splits: splits, expense: expense, group: group, currentUserId: TestData.currentUser.id)
            } else {
                do {
                    let request = CreateSharedExpenseRequest(
                        groupId: group.id,
                        description: description.trimmingCharacters(in: .whitespaces),
                        category: selectedCategory,
                        totalAmount: String(format: "%.2f", Double(amount) ?? 0),
                        splits: splits
                    )
                    let expense = try await APIService.shared.createExpense(request)
                    onAdd(expense)
                    if let userId = APIService.shared.currentUser?.id {
                        saveLocalGroupShare(splits: expense.splits ?? splits, expense: expense, group: group, currentUserId: userId)
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSaving = false
                    return
                }
            }
            isSaving = false
            dismiss()
        }
    }
    
    private func saveLocalGroupShare(splits: [ExpenseSplit], expense: SharedExpense, group: SplitGroup, currentUserId: UUID) {
        guard let userSplit = splits.first(where: { $0.userId == currentUserId }),
              let personalAmount = Double(userSplit.amount), personalAmount > 0 else { return }
        
        let localExpense = Expense(
            amount: personalAmount,
            category: selectedCategory,
            date: Date(),
            expenseDescription: "\(expense.description) (\(group.name))",
            notes: "Your share from group split",
            groupId: group.id,
            groupName: group.name
        )
        modelContext.insert(localExpense)
        try? modelContext.save()
    }
    
    // MARK: - Formatters
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Shared Components

struct QuickAmountButton: View {
    let amount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("₹\(amount)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.teal.opacity(0.1))
                .foregroundColor(.teal)
                .cornerRadius(8)
        }
        .buttonStyle(.borderless)
    }
}

struct QuickDateButton: View {
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.teal.opacity(0.1))
                .foregroundColor(.teal)
                .cornerRadius(8)
        }
        .buttonStyle(.borderless)
    }
}

struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategory: String
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    private var visibleCustom: [CustomCategory] {
        customCategories.filter { !$0.isHidden }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !visibleCustom.isEmpty {
                    Section("Your Categories") {
                        ForEach(visibleCustom) { category in
                            Button {
                                selectedCategory = category.name
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundColor(Color(hex: category.color))
                                        .frame(width: 30)
                                    Text(category.name)
                                    Spacer()
                                    if selectedCategory == category.name {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.teal)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                Section("Default Categories") {
                    ForEach(PredefinedCategory.allCases) { category in
                        Button {
                            selectedCategory = category.rawValue
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                    .frame(width: 30)
                                Text(category.rawValue)
                                Spacer()
                                if selectedCategory == category.rawValue {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.teal)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DatePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TimePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTime: Date
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .padding()
                Spacer()
            }
            .navigationTitle("Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Personal - New") {
    AddExpenseView()
        .modelContainer(for: [Expense.self, CustomCategory.self], inMemory: true)
}

#Preview("Personal - Edit") {
    let expense = Expense(amount: 450, category: "Food & Dining", date: Date(), expenseDescription: "Lunch at cafe", notes: "With colleagues")
    AddExpenseView(expenseToEdit: expense)
        .modelContainer(for: [Expense.self, CustomCategory.self], inMemory: true)
}

#Preview("Shared - Small Group") {
    let group = TestData.testGroups[0]
    AddExpenseView(mode: .shared(group: group, members: TestData.testGroupMembers[group.id] ?? []) { _ in })
        .modelContainer(for: Expense.self, inMemory: true)
}

#Preview("Shared - Large Group") {
    let group = TestData.testGroups[2]
    AddExpenseView(mode: .shared(group: group, members: TestData.testGroupMembers[group.id] ?? []) { _ in })
        .modelContainer(for: Expense.self, inMemory: true)
}
