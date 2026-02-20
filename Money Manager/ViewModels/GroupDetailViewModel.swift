import SwiftUI
import Combine

enum GroupSection: String, CaseIterable {
    case expenses = "Expenses"
    case balances = "Balances"
    case members = "Members"
}

@MainActor
class GroupDetailViewModel: ObservableObject {
    @Published var selectedSection: GroupSection = .expenses
    @Published var expenses: [SharedExpense] = []
    @Published var balances: [UserBalance] = []
    @Published var members: [APIUser] = []
    @Published var isLoading = false
    @Published var showAddExpense = false
    @Published var showSettlement = false
    @Published var showAddMember = false
    @Published var addMemberError: String?
    @Published var pendingMemberIds: Set<UUID> = []
    
    let group: SplitGroup
    var expensesParam: [SharedExpense]?
    var balancesParam: [UserBalance]?
    var membersParam: [APIUser]?
    
    var groupTotal: Double {
        expenses.compactMap { Double($0.totalAmount) }.reduce(0, +)
    }
    
    var hasUnsettledBalances: Bool {
        balances.contains { (Double($0.amount) ?? 0) != 0 }
    }
    
    init(group: SplitGroup, 
         expenses: [SharedExpense]? = nil,
         balances: [UserBalance]? = nil,
         members: [APIUser]? = nil) {
        self.group = group
        self.expensesParam = expenses
        self.balancesParam = balances
        self.membersParam = members
        self.expenses = expenses ?? []
        self.balances = balances ?? []
        self.members = members ?? []
    }
    
    func loadData() async {
        isLoading = true
        
        if let expensesParam, let balancesParam, let membersParam {
            expenses = expensesParam
            balances = balancesParam
            members = membersParam
        } else if useTestData {
            try? await Task.sleep(for: .milliseconds(300))
            expenses = TestData.testSharedExpenses[group.id] ?? []
            balances = TestData.testBalances[group.id] ?? []
            members = TestData.testGroupMembers[group.id] ?? []
        } else {
            do {
                async let fetchedExpenses = APIService.shared.getGroupExpenses(groupId: group.id)
                async let fetchedBalances = APIService.shared.getBalances(groupId: group.id)
                expenses = try await fetchedExpenses
                balances = try await fetchedBalances
            } catch {
                // Handle error
            }
        }
        
        isLoading = false
    }
    
    func recalculateBalances() {
        var balanceMap: [UUID: Double] = [:]
        for member in members {
            balanceMap[member.id] = 0
        }
        for expense in expenses {
            let paidBy = expense.paidBy
            let total = Double(expense.totalAmount) ?? 0
            balanceMap[paidBy, default: 0] += total
            
            if let splits = expense.splits {
                for split in splits {
                    let amt = Double(split.amount) ?? 0
                    balanceMap[split.userId, default: 0] -= amt
                }
            }
        }
        balances = balanceMap.map { UserBalance(userId: $0.key, amount: String(format: "%.2f", $0.value)) }
            .sorted { abs(Double($0.amount) ?? 0) > abs(Double($1.amount) ?? 0) }
    }
    
    func addExpense(_ newExpense: SharedExpense) {
        expenses.insert(newExpense, at: 0)
        recalculateBalances()
    }
    
    func addMember(email: String) {
        let tempId = UUID()
        let newMember = APIUser(
            id: tempId,
            email: email,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        members.append(newMember)
        pendingMemberIds.insert(tempId)
        showAddMember = false
        
        Task {
            do {
                if useTestData {
                    try await Task.sleep(for: .seconds(Int.random(in: 5...10)))
                } else {
                    _ = try await APIService.shared.addMember(groupId: group.id, userEmail: email)
                }
                pendingMemberIds.remove(tempId)
            } catch {
                addMemberError = error.localizedDescription
            }
        }
    }
}
