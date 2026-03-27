import SwiftUI
import SwiftData

enum AddExpenseMode {
    case personal(editing: Expense? = nil)
    case shared(group: APIGroupWithDetails, members: [APIGroupMember], onAdd: (APIGroupExpense) -> Void)
}

enum SplitType: String, CaseIterable {
    case equal  = "Equal"
    case custom = "Custom"
}

@MainActor
@Observable class AddExpenseViewModel {
    var amount = ""
    var selectedCategory = ""
    var description = ""
    var notes = ""
    var showCategoryPicker = false
    var showRecurringSheet = false
    var showError = false
    var errorMessage = ""
    var isSaving = false

    var selectedDate = Date()
    var selectedTime = Date()
    var hasTime = true

    // Shared expense fields
    var paidByUserId: UUID?
    var splitType: SplitType = .equal
    var selectedMembers: Set<UUID> = []
    var customAmounts: [UUID: String] = [:]

    let mode: AddExpenseMode
    var modelContext: ModelContext?
    var customCategories: [CustomCategory] = []
    private let groupService: GroupServiceProtocol
    private let changeQueue: ChangeQueueManagerProtocol
    private let auth: AuthServiceProtocol

    // MARK: - Computed

    var isShared: Bool {
        if case .shared = mode { return true }
        return false
    }

    var navigationTitle: String {
        switch mode {
        case .personal(let editing): return editing != nil ? "Edit Expense" : "Add Expense"
        case .shared:                return "Add Group Expense"
        }
    }

    var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0,
              !selectedCategory.isEmpty else { return false }

        if case .shared = mode {
            guard !description.trimmingCharacters(in: .whitespaces).isEmpty,
                  paidByUserId != nil,
                  !selectedMembers.isEmpty else { return false }
            if splitType == .custom { return splitMatchesTotal }
        }
        return true
    }

    var equalShareText: String {
        guard let total = Double(amount), total > 0, !selectedMembers.isEmpty else {
            return "\(CurrencyFormatter.currentSymbol)0"
        }
        return CurrencyFormatter.format(total / Double(selectedMembers.count), showDecimals: true)
    }

    var customSplitTotal: Double {
        selectedMembers.compactMap { Double(customAmounts[$0] ?? "") }.reduce(0, +)
    }

    var splitMatchesTotal: Bool {
        guard let total = Double(amount) else { return false }
        return abs(customSplitTotal - total) < 0.01
    }

    // MARK: - Init

    init(
        mode: AddExpenseMode = .personal(),
        groupService: GroupServiceProtocol = GroupService.shared,
        changeQueue: ChangeQueueManagerProtocol = changeQueueManager,
        auth: AuthServiceProtocol = authService
    ) {
        self.mode = mode
        self.groupService = groupService
        self.changeQueue = changeQueue
        self.auth = auth
        setup()
    }

    func setup() {
        switch mode {
        case .personal(let editing):
            guard let expense = editing else { return }
            amount = expense.amount.formatted(.number.precision(.fractionLength(2)))
            selectedCategory = expense.category
            selectedDate = expense.date
            selectedTime = expense.time ?? Date()
            hasTime = expense.time != nil
            description = expense.expenseDescription ?? ""
            notes = expense.notes ?? ""

        case .shared(_, let members, _):
            paidByUserId = auth.currentUser?.id
            selectedMembers = Set(members.map(\.id))
        }
    }

    // MARK: - Helpers

    func customAmountBinding(for userId: UUID) -> Binding<String> {
        Binding(
            get: { [self] in customAmounts[userId] ?? "" },
            set: { [self] in customAmounts[userId] = $0 }
        )
    }

    func displayName(for member: APIGroupMember) -> String {
        member.username
    }

    func toggleMember(_ id: UUID) {
        if selectedMembers.contains(id) {
            selectedMembers.remove(id)
            customAmounts.removeValue(forKey: id)
        } else {
            selectedMembers.insert(id)
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

    // MARK: - Save

    func save(completion: @escaping () -> Void) {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }

        isSaving = true

        switch mode {
        case .personal:
            savePersonal(amountValue: amountValue, completion: completion)
        case .shared(let group, _, let onAdd):
            saveShared(amountValue: amountValue, group: group, onAdd: onAdd, completion: completion)
        }
    }

    // MARK: - Private: personal save (unchanged logic)

    private func savePersonal(amountValue: Double, completion: @escaping () -> Void) {
        guard let modelContext else {
            isSaving = false
            return
        }

        let calendar = Calendar.current
        var expenseDate = calendar.startOfDay(for: selectedDate)
        if hasTime {
            let tc = calendar.dateComponents([.hour, .minute], from: selectedTime)
            expenseDate = calendar.date(bySettingHour: tc.hour ?? 0,
                                        minute: tc.minute ?? 0,
                                        second: 0,
                                        of: selectedDate) ?? selectedDate
        }

        let expenseID: UUID
        let action: String
        let endpoint: String
        let httpMethod: String
        var payload: Data?

        let resolvedCategoryId = customCategories.first(where: { $0.name == selectedCategory })?.id

        if case .personal(let existing) = mode, let existingExpense = existing {
            existingExpense.amount = amountValue
            existingExpense.category = selectedCategory
            existingExpense.categoryId = resolvedCategoryId
            existingExpense.date = expenseDate
            existingExpense.time = hasTime ? selectedTime : nil
            existingExpense.expenseDescription = description.isEmpty ? nil : description
            existingExpense.notes = notes.isEmpty ? nil : notes
            existingExpense.updatedAt = Date()
            expenseID = existingExpense.id
            action = "update"
            endpoint = "/expenses"
            httpMethod = "PUT"
            payload = try? APIClient.apiEncoder.encode(existingExpense.toUpdateRequest())
        } else {
            let expense = Expense(
                amount: amountValue,
                category: selectedCategory,
                date: expenseDate,
                time: hasTime ? selectedTime : nil,
                expenseDescription: description.isEmpty ? nil : description,
                notes: notes.isEmpty ? nil : notes,
                categoryId: resolvedCategoryId
            )
            modelContext.insert(expense)
            expenseID = expense.id
            action = "create"
            endpoint = "/expenses"
            httpMethod = "POST"
            payload = try? APIClient.apiEncoder.encode(expense.toCreateRequest())
        }

        do {
            try modelContext.save()
            AppLogger.data.info("Expense saved: \(expenseID) action=\(action)")
            changeQueue.enqueue(
                entityType: "expense",
                entityID: expenseID,
                action: action,
                endpoint: endpoint,
                httpMethod: httpMethod,
                payload: payload,
                context: modelContext
            )
            if NetworkMonitor.shared.isConnected {
                Task { await changeQueue.replayAll(context: modelContext) }
            }
        } catch {
            AppLogger.data.error("Failed to save expense: \(error)")
            errorMessage = "Failed to save expense"
            showError = true
            isSaving = false
            return
        }

        isSaving = false
        completion()
    }

    // MARK: - Private: shared save

    private func saveShared(
        amountValue: Double,
        group: APIGroupWithDetails,
        onAdd: @escaping (APIGroupExpense) -> Void,
        completion: @escaping () -> Void
    ) {
        guard let paidBy = paidByUserId else {
            errorMessage = "Please select who paid"
            showError = true
            isSaving = false
            return
        }

        let splits: [APIExpenseSplit]
        if splitType == .equal {
            let share = amountValue / Double(max(selectedMembers.count, 1))
            splits = selectedMembers.map {
                APIExpenseSplit(userId: $0, amount: share.formatted(.number.precision(.fractionLength(2)).grouping(.never)))
            }
        } else {
            splits = selectedMembers.compactMap { id in
                guard let raw = customAmounts[id], let _ = Double(raw) else { return nil }
                return APIExpenseSplit(userId: id, amount: raw)
            }
        }

        let request = APICreateSharedExpenseRequest(
            groupId: group.id,
            description: description.trimmingCharacters(in: .whitespaces),
            category: selectedCategory,
            totalAmount: amountValue.formatted(.number.precision(.fractionLength(2)).grouping(.never)),
            splits: splits
        )

        Task {
            do {
                let expense = try await groupService.createSharedExpense(request)
                onAdd(expense)
                isSaving = false
                completion()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
                isSaving = false
            }
        }
    }
}
