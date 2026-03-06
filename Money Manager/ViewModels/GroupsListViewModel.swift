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
        guard let userId = currentUserId else { return 0 }
        var total = 0.0
        for group in groups {
            if let balances = groupBalances[group.id],
               let userBalance = balances.first(where: { $0.userId == userId }) {
                total += Double(userBalance.amount) ?? 0
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
        guard let userId = currentUserId,
              let balances = groupBalances[groupId],
              let userBalance = balances.first(where: { $0.userId == userId }) else { return 0 }
        return Double(userBalance.amount) ?? 0
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
        if useTestData {
            groups = TestData.testGroups
            groupMembers = TestData.testGroupMembers
            groupExpenses = TestData.testSharedExpenses
            groupBalances = TestData.testBalances
            isLoading = false
            print("[GroupsList] Loaded test data — \(groups.count) groups")
            return
        }
        
        do {
            let fetchedGroups = try await APIService.shared.getGroups()
            groups = fetchedGroups
            print("[GroupsList] API returned \(fetchedGroups.count) groups")
            
            for group in fetchedGroups {
                // Members come from the rich group response, or fetch separately
                if let members = group.members {
                    groupMembers[group.id] = members.map { APIUser(id: $0.id, email: $0.email, username: $0.username, createdAt: $0.createdAt) }
                    print("[GroupsList] Group '\(group.name)' — \(members.count) members from response")
                } else {
                    // Fetch members separately if not in group response
                    do {
                        let fetchedMembers = try await APIService.shared.getGroupMembers(groupId: group.id)
                        groupMembers[group.id] = fetchedMembers.map { APIUser(id: $0.id, email: $0.email, username: $0.username, createdAt: $0.createdAt) }
                        print("[GroupsList] Group '\(group.name)' — \(fetchedMembers.count) members fetched separately")
                    } catch {
                        print("[GroupsList] Failed to fetch members for group '\(group.name)': \(error)")
                    }
                }
                
                // Balances come from the rich group response, or fetch separately
                if let balances = group.balances {
                    groupBalances[group.id] = balances
                    print("[GroupsList] Group '\(group.name)' — \(balances.count) balances: \(balances.map { "\($0.userId.uuidString.prefix(8))=\($0.amount)" }.joined(separator: ", "))")
                } else {
                    // Fetch balances separately if not in group response
                    do {
                        let fetchedBalances = try await APIService.shared.getBalances(groupId: group.id)
                        groupBalances[group.id] = fetchedBalances
                        print("[GroupsList] Group '\(group.name)' — \(fetchedBalances.count) balances fetched separately")
                    } catch {
                        print("[GroupsList] Failed to fetch balances for group '\(group.name)': \(error)")
                    }
                }
                
                // Expenses still need a separate call
                do {
                    let expenses = try await APIService.shared.getGroupExpenses(groupId: group.id)
                    groupExpenses[group.id] = expenses
                    print("[GroupsList] Group '\(group.name)' — \(expenses.count) expenses fetched")
                } catch {
                    print("[GroupsList] Failed to load expenses for group '\(group.name)': \(error)")
                }
            }
            
            print("[GroupsList] Current user ID: \(currentUserId?.uuidString ?? "nil")")
            print("[GroupsList] Net balance: \(netBalance)")
        } catch {
            print("[GroupsList] Failed to load groups: \(error)")
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
