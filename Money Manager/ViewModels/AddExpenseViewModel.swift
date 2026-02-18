import SwiftUI
import SwiftData
import Combine

enum AddExpenseMode {
    case personal(editing: Expense? = nil)
    case shared(group: SplitGroup, members: [APIUser], onAdd: (SharedExpense) -> Void)
}

enum SplitType: String, CaseIterable {
    case equal = "Equal"
    case custom = "Custom"
}

@MainActor
class AddExpenseViewModel: ObservableObject {
    @Published var amount = ""
    @Published var selectedCategory = ""
    @Published var description = ""
    @Published var notes = ""
    @Published var showCategoryPicker = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isSaving = false
    
    @Published var selectedDate = Date()
    @Published var selectedTime = Date()
    @Published var hasTime = true
    @Published var isRecurring = false
    @Published var showDatePicker = false
    @Published var showTimePicker = false
    
    @Published var paidByUserId: UUID?
    @Published var splitType: SplitType = .equal
    @Published var selectedMembers: Set<UUID> = []
    @Published var customAmounts: [UUID: String] = [:]
    
    let mode: AddExpenseMode
    private var modelContext: ModelContext?
    
    var isShared: Bool {
        if case .shared = mode { return true }
        return false
    }
    
    var navigationTitle: String {
        switch mode {
        case .personal(let editing):
            return editing != nil ? "Edit Expense" : "Add Expense"
        case .shared:
            return "Add Shared Expense"
        }
    }
    
    var isValid: Bool {
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
    
    var equalShareText: String {
        guard let total = Double(amount), total > 0, !selectedMembers.isEmpty else { return "₹0" }
        return CurrencyFormatter.format(total / Double(selectedMembers.count), showDecimals: true)
    }
    
    var customSplitTotal: Double {
        selectedMembers.compactMap { Double(customAmounts[$0] ?? "") }.reduce(0, +)
    }
    
    var splitMatchesTotal: Bool {
        guard let total = Double(amount) else { return false }
        return abs(customSplitTotal - total) < 0.01
    }
    
    init(mode: AddExpenseMode) {
        self.mode = mode
    }
    
    func configure(modelContext: ModelContext?) {
        self.modelContext = modelContext
        setup()
    }
    
    func setup() {
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
    
    func binding(for userId: UUID) -> Binding<String> {
        Binding(
            get: { [self] in customAmounts[userId] ?? "" },
            set: { [self] in customAmounts[userId] = $0 }
        )
    }
    
    func toggleMember(_ id: UUID) {
        if selectedMembers.contains(id) {
            selectedMembers.remove(id)
        } else {
            selectedMembers.insert(id)
        }
    }
    
    func displayName(for member: APIUser) -> String {
        member.email.components(separatedBy: "@").first?.capitalized ?? member.email
    }
    
    func buildSplits() -> [ExpenseSplit] {
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
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func save(completion: @escaping () -> Void) {
        switch mode {
        case .personal:
            savePersonalExpense(completion: completion)
        case .shared:
            saveSharedExpense(completion: completion)
        }
    }
    
    private func savePersonalExpense(completion: @escaping () -> Void) {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Amount must be greater than 0"
            showError = true
            return
        }
        
        guard let modelContext = modelContext else { return }
        
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
        
        let expense = Expense(
            amount: amountValue,
            category: selectedCategory,
            date: expenseDate,
            time: hasTime ? selectedTime : nil,
            expenseDescription: description.isEmpty ? nil : description,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(expense)
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save expense locally"
            showError = true
            isSaving = false
            return
        }
        
        Task {
            if !useTestData {
                let request = CreatePersonalExpenseRequest(
                    categoryId: nil,
                    amount: String(format: "%.2f", amountValue),
                    description: description.isEmpty ? nil : description,
                    notes: notes.isEmpty ? nil : notes,
                    expenseDate: ISO8601DateFormatter().string(from: expenseDate)
                )
                SyncService.shared.queueForSync(
                    itemType: .personalExpense,
                    itemId: expense.id,
                    action: .create,
                    payload: request
                )
            }
            
            isSaving = false
            completion()
        }
    }
    
    private func saveSharedExpense(completion: @escaping () -> Void) {
        guard case .shared(let group, _, let onAdd) = mode,
              let paidBy = paidByUserId else { return }
        
        let splits = buildSplits()
        
        guard let modelContext = modelContext else { return }
        
        isSaving = true
        
        let totalAmount = Double(amount) ?? 0
        let expenseDescription = description.trimmingCharacters(in: .whitespaces)
        
        let _ = createLocalGroupExpense(splits: splits, group: group, paidBy: paidBy, modelContext: modelContext)
        
        Task {
            if useTestData {
                try? await Task.sleep(for: .milliseconds(300))
                let expense = SharedExpense(
                    id: UUID(),
                    groupId: group.id,
                    description: expenseDescription,
                    category: selectedCategory,
                    totalAmount: String(format: "%.2f", totalAmount),
                    paidBy: paidBy,
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    splits: splits
                )
                onAdd(expense)
            } else {
                let request = CreateSharedExpenseRequest(
                    groupId: group.id,
                    description: expenseDescription,
                    category: selectedCategory,
                    totalAmount: String(format: "%.2f", totalAmount),
                    splits: splits
                )
                
                SyncService.shared.queueForSync(
                    itemType: .sharedExpense,
                    itemId: UUID(),
                    action: .create,
                    payload: request
                )
            }
            
            isSaving = false
            completion()
        }
    }
    
    private func createLocalGroupExpense(splits: [ExpenseSplit], group: SplitGroup, paidBy: UUID, modelContext: ModelContext) -> Expense {
        let currentUserId = useTestData ? TestData.currentUser.id : (APIService.shared.currentUser?.id ?? UUID())
        
        let userSplit = splits.first(where: { $0.userId == currentUserId })
        let personalAmount = userSplit.flatMap { Double($0.amount) } ?? 0
        
        let expense = Expense(
            amount: personalAmount,
            category: selectedCategory,
            date: Date(),
            expenseDescription: "\(description) (\(group.name))",
            notes: "Your share from group split",
            groupId: group.id,
            groupName: group.name
        )
        modelContext.insert(expense)
        try? modelContext.save()
        
        return expense
    }
}
