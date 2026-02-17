import SwiftUI
import SwiftData

struct AddSharedExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let group: SplitGroup
    let members: [APIUser]
    var onAdd: (SharedExpense) -> Void
    
    @State private var description = ""
    @State private var selectedCategory: String = ""
    @State private var totalAmount = ""
    @State private var paidByUserId: UUID?
    @State private var splitType: SplitType = .equal
    @State private var selectedMembers: Set<UUID> = []
    @State private var customAmounts: [UUID: String] = [:]
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCategoryPicker = false
    
    enum SplitType: String, CaseIterable {
        case equal = "Equal"
        case custom = "Custom"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description *")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g., Dinner, Cab, Groceries", text: $description)
                            .textInputAutocapitalization(.sentences)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category *")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showCategoryPicker = true
                        }) {
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
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Amount *")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $totalAmount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            QuickAmountButton(amount: 500) { totalAmount = "500" }
                            QuickAmountButton(amount: 1000) { totalAmount = "1000" }
                            QuickAmountButton(amount: 2000) { totalAmount = "2000" }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Paid By") {
                    ForEach(members) { member in
                        Button {
                            paidByUserId = member.id
                        } label: {
                            HStack {
                                Text(MockData.nameForUser(member.id))
                                    .foregroundColor(.primary)
                                
                                Text(member.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if paidByUserId == member.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.teal)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
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
                
                Section {
                    ForEach(members) { member in
                        HStack {
                            Button {
                                toggleMember(member.id)
                            } label: {
                                HStack {
                                    Image(systemName: selectedMembers.contains(member.id) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selectedMembers.contains(member.id) ? .teal : .secondary)
                                    
                                    Text(MockData.nameForUser(member.id))
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
                
                if splitType == .custom && !selectedMembers.isEmpty {
                    Section {
                        HStack {
                            Text("Total split")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(CurrencyFormatter.format(customSplitTotal, showDecimals: true))
                                .fontWeight(.semibold)
                                .foregroundColor(splitMatchesTotal ? .green : .red)
                        }
                        
                        if let total = Double(totalAmount), total > 0 {
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
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { addExpense() }
                        .fontWeight(.semibold)
                        .disabled(!isFormValid || isLoading)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showCategoryPicker) {
                NavigationStack {
                    List {
                        ForEach(PredefinedCategory.allCases) { category in
                            Button(action: {
                                selectedCategory = category.rawValue
                                showCategoryPicker = false
                            }) {
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
            .onAppear {
                if paidByUserId == nil {
                    paidByUserId = MockData.useDummyData ? MockData.currentUser.id : APIService.shared.currentUser?.id
                }
                selectedMembers = Set(members.map(\.id))
            }
        }
    }
    
    // MARK: - Computed
    
    private var equalShareText: String {
        guard let total = Double(totalAmount), total > 0, !selectedMembers.isEmpty else {
            return "₹0"
        }
        let share = total / Double(selectedMembers.count)
        return CurrencyFormatter.format(share, showDecimals: true)
    }
    
    private var customSplitTotal: Double {
        selectedMembers.compactMap { Double(customAmounts[$0] ?? "") }.reduce(0, +)
    }
    
    private var splitMatchesTotal: Bool {
        guard let total = Double(totalAmount) else { return false }
        return abs(customSplitTotal - total) < 0.01
    }
    
    private var isFormValid: Bool {
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty,
              !selectedCategory.isEmpty,
              let total = Double(totalAmount), total > 0,
              paidByUserId != nil,
              !selectedMembers.isEmpty else {
            return false
        }
        
        if splitType == .custom {
            return splitMatchesTotal
        }
        return true
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
    
    private func buildSplits() -> [ExpenseSplit] {
        guard let total = Double(totalAmount) else { return [] }
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
    
    // MARK: - Submit
    
    private func addExpense() {
        let splits = buildSplits()
        guard let paidBy = paidByUserId else { return }
        
        isLoading = true
        Task {
            if MockData.useDummyData {
                try? await Task.sleep(for: .milliseconds(300))
                let expense = SharedExpense(
                    id: UUID(),
                    groupId: group.id,
                    description: description.trimmingCharacters(in: .whitespaces),
                    category: selectedCategory,
                    totalAmount: String(format: "%.2f", Double(totalAmount) ?? 0),
                    paidBy: paidBy,
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    splits: splits
                )
                onAdd(expense)
                let currentUserId = MockData.currentUser.id
                if let userSplit = splits.first(where: { $0.userId == currentUserId }) {
                    let personalAmount = Double(userSplit.amount) ?? 0
                    if personalAmount > 0 {
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
                }
            } else {
                do {
                    let request = CreateSharedExpenseRequest(
                        groupId: group.id,
                        description: description.trimmingCharacters(in: .whitespaces),
                        category: selectedCategory,
                        totalAmount: String(format: "%.2f", Double(totalAmount) ?? 0),
                        splits: splits
                    )
                    let expense = try await APIService.shared.createExpense(request)
                    onAdd(expense)
                    let currentUserId = APIService.shared.currentUser?.id
                    if let expenseSplits = expense.splits ?? splits as [ExpenseSplit]?,
                       let userId = currentUserId,
                       let userSplit = expenseSplits.first(where: { $0.userId == userId }) {
                        let personalAmount = Double(userSplit.amount) ?? 0
                        if personalAmount > 0 {
                            let localExpense = Expense(
                                amount: personalAmount,
                                category: "Group Expense",
                                date: Date(),
                                expenseDescription: "\(expense.description) (\(group.name))",
                                notes: "Your share from group split",
                                groupId: group.id,
                                groupName: group.name
                            )
                            modelContext.insert(localExpense)
                            try? modelContext.save()
                        }
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                    return
                }
            }
            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    AddSharedExpenseView(
        group: MockData.groups[0],
        members: MockData.groupMembers[MockData.groups[0].id]!
    ) { _ in }
}
