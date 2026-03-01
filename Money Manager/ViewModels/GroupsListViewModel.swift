import SwiftUI
import Combine

enum ViewTab {
    case groups
    case activities
}

@MainActor
class GroupsListViewModel: ObservableObject {
    @Published var groups: [SplitGroup] = []
    @Published var groupBalances: [UUID: [UserBalance]] = [:]
    @Published var groupExpenses: [UUID: [SharedExpense]] = [:]
    @Published var groupMembers: [UUID: [APIUser]] = [:]
    @Published var showCreateGroup = false
    @Published var isLoading = false
    @Published var selectedTab: ViewTab = .groups
    @Published var searchText = ""
    
    var groupsParam: [SplitGroup]?
    var balancesParam: [UUID: [UserBalance]] = [:]
    var expensesParam: [UUID: [SharedExpense]] = [:]
    var membersParam: [UUID: [APIUser]] = [:]
    
    var currentUserId: UUID? {
        if useTestData || groupsParam != nil {
            return TestData.currentUser.id
        }
        return APIService.shared.currentUser?.id
    }
    
    var filteredGroups: [SplitGroup] {
        if searchText.isEmpty {
            return groups
        }
        return groups.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var netBalance: Double {
        var total = 0.0
        for group in groups {
            if let balances = groupBalances[group.id] {
                for balance in balances {
                    total += Double(balance.amount) ?? 0
                }
            }
        }
        return total
    }
    
    var recentActivity: [(expense: SharedExpense, groupName: String)] {
        var all: [(expense: SharedExpense, groupName: String)] = []
        for group in groups {
            if let expenses = groupExpenses[group.id] {
                for expense in expenses {
                    all.append((expense: expense, groupName: group.name))
                }
            }
        }
        return all
            .sorted { $0.expense.createdAt > $1.expense.createdAt }
            .prefix(5)
            .map { $0 }
    }
    
    var filteredActivity: [(expense: SharedExpense, groupName: String)] {
        if searchText.isEmpty {
            return recentActivity
        }
        let query = searchText.lowercased()
        return recentActivity.filter { item in
            item.groupName.lowercased().contains(query) ||
            item.expense.description.lowercased().contains(query)
        }
    }
    
    init(groups: [SplitGroup]? = nil, 
         balances: [UUID: [UserBalance]] = [:],
         expenses: [UUID: [SharedExpense]] = [:],
         members: [UUID: [APIUser]] = [:]) {
        self.groupsParam = groups
        self.balancesParam = balances
        self.expensesParam = expenses
        self.membersParam = members
        self.groups = groups ?? []
        self.groupBalances = balances
        self.groupExpenses = expenses
        self.groupMembers = members
    }
    
    func userBalance(for groupId: UUID) -> Double {
        guard let balances = groupBalances[groupId] else { return 0 }
        return balances.reduce(0.0) { $0 + (Double($1.amount) ?? 0) }
    }
    
    func nameForUser(_ userId: UUID) -> String {
        for members in groupMembers.values {
            if let user = members.first(where: { $0.id == userId }) {
                return user.email.components(separatedBy: "@").first?.capitalized ?? user.email
            }
        }
        return "Unknown"
    }
    
    func relativeTime(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "" }
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        let weeks = Int(interval / 604800)
        
        if minutes < 1 { return "now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        if days < 7 { return "\(days)d ago" }
        return "\(weeks)w ago"
    }
    
    func loadFromDB(dbGroups: [SplitGroupModel], dbMembers: [GroupMemberModel], dbExpenses: [GroupExpenseModel], dbBalances: [GroupBalanceModel]) {
        groups = dbGroups.map { SplitGroup(id: $0.id, name: $0.name, createdBy: $0.createdBy, createdAt: $0.createdAt) }
        
        var membersDict: [UUID: [APIUser]] = [:]
        var expensesDict: [UUID: [SharedExpense]] = [:]
        var balancesDict: [UUID: [UserBalance]] = [:]
        
        for group in groups ?? [] {
            let groupMembers = dbMembers.filter { $0.group?.id == group.id }
            membersDict[group.id] = groupMembers.map { APIUser(id: $0.id, email: $0.email, username: $0.username, createdAt: $0.createdAt) }
            
            let groupExpenses = dbExpenses.filter { $0.group?.id == group.id }
            expensesDict[group.id] = groupExpenses.map { exp in
                SharedExpense(id: exp.id, groupId: group.id, description: exp.expenseDescription, category: exp.category, totalAmount: String(exp.totalAmount), paidBy: exp.paidBy, createdAt: exp.createdAt, splits: nil)
            }
            
            let groupBalances = dbBalances.filter { $0.group?.id == group.id }
            balancesDict[group.id] = groupBalances.map { bal in
                UserBalance(userId: bal.userId, amount: String(bal.amount))
            }
        }
        
        groupMembers = membersDict
        groupExpenses = expensesDict
        groupBalances = balancesDict
    }
    
    func refreshFromAPI() async {
        guard !useTestData else { return }
        
        do {
            let fetchedGroups = try await APIService.shared.getGroups()
            groups = fetchedGroups
            
            for group in fetchedGroups {
                async let expensesTask = APIService.shared.getGroupExpenses(groupId: group.id)
                async let balancesTask = APIService.shared.getBalances(groupId: group.id)
                async let membersTask = APIService.shared.getGroupMembers(groupId: group.id)
                
                let (expenses, balances, members) = try await (expensesTask, balancesTask, membersTask)
                groupExpenses[group.id] = expenses
                groupBalances[group.id] = balances
                groupMembers[group.id] = members
            }
        } catch {
            print("Failed to load groups: \(error)")
        }
        
        isLoading = false
    }
    
    func loadGroups() {
        isLoading = false
    }
    
    func addGroup(_ newGroup: SplitGroup) {
        groups.insert(newGroup, at: 0)
    }
}
