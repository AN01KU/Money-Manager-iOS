//
//  GroupsListViewModel.swift
//  Money Manager
//

import SwiftUI

private let activitySectionDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMMM dd"
    return f
}()

enum GroupsTab {
    case groups
    case activities
}

enum ActivityItem: Identifiable {
    case transaction(APIGroupTransaction, groupName: String)
    case settlement(APISettlement, groupName: String, memberMap: [UUID: String])

    var id: UUID {
        switch self {
        case .transaction(let tx, _): return tx.id
        case .settlement(let s, _, _): return s.id
        }
    }

    var date: Date {
        switch self {
        case .transaction(let tx, _): return tx.date
        case .settlement(let s, _, _): return s.createdAt
        }
    }

    var groupName: String {
        switch self {
        case .transaction(_, let name): return name
        case .settlement(_, let name, _): return name
        }
    }
}

@MainActor
@Observable
final class GroupsListViewModel {
    var groups: [APIGroupWithDetails] = []
    var isLoading = false
    var errorMessage: String?
    var showCreateGroup = false
    var selectedTab: GroupsTab = .groups
    var searchText = ""

    let groupService: GroupServiceProtocol
    private(set) var currentUserId: UUID?

    init(groupService: GroupServiceProtocol = GroupService.shared, currentUserId: UUID? = nil) {
        self.groupService = groupService
        self.currentUserId = currentUserId
    }

    func setCurrentUser(_ userId: UUID?) {
        currentUserId = userId
    }

    var filteredGroups: [APIGroupWithDetails] {
        guard !searchText.isEmpty else { return groups }
        return groups.filter { $0.name.localizedStandardContains(searchText) }
    }

    /// Net balance across all groups for the current user.
    /// Positive = user owes others. Negative = user is owed.
    var netBalance: Double {
        guard let userId = currentUserId else { return 0 }
        return groups.reduce(0.0) { total, group in
            let balance = group.balances.first(where: { $0.userId == userId })
            return total + (balance?.amount ?? 0)
        }
    }

    var recentActivity: [ActivityItem] = []

    var filteredActivity: [ActivityItem] {
        guard !searchText.isEmpty else { return recentActivity }
        return recentActivity.filter { item in
            if item.groupName.localizedStandardContains(searchText) { return true }
            if case .transaction(let tx, _) = item {
                return tx.description?.localizedStandardContains(searchText) ?? false
            }
            return false
        }
    }

    var groupedActivity: [ActivitySection] {
        let calendar = Calendar.current
        var grouped: [String: [ActivityItem]] = [:]

        for item in filteredActivity {
            let day = calendar.startOfDay(for: item.date)
            let key = calendar.isDateInToday(day)
                ? "TODAY"
                : activitySectionDateFormatter.string(from: day).uppercased()
            grouped[key, default: []].append(item)
        }

        return grouped
            .map { ActivitySection(id: $0.key, label: $0.key, items: $0.value) }
            .sorted { a, b in
                if a.id == "TODAY" { return true }
                if b.id == "TODAY" { return false }
                return a.id > b.id
            }
    }

    // MARK: - Actions

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            groups = try await groupService.fetchGroups()
            await loadActivity()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func loadActivity() async {
        var items: [ActivityItem] = []

        await withTaskGroup(of: (String, [APIGroupTransaction], [APISettlement], [APIGroupMember]).self) { taskGroup in
            for group in groups {
                taskGroup.addTask {
                    let transactions = (try? await self.groupService.fetchGroupTransactions(groupId: group.id)) ?? []
                    let details = try? await self.groupService.fetchGroupDetails(groupId: group.id)
                    let settlements = details?.group.settlements ?? []
                    let members = details?.group.members ?? group.members
                    return (group.name, transactions, settlements, members)
                }
            }
            for await (groupName, transactions, settlements, members) in taskGroup {
                let memberMap = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.username) })
                for tx in transactions {
                    items.append(.transaction(tx, groupName: groupName))
                }
                if let userId = currentUserId {
                    for settlement in settlements where settlement.fromUser == userId || settlement.toUser == userId {
                        items.append(.settlement(settlement, groupName: groupName, memberMap: memberMap))
                    }
                }
            }
        }
        recentActivity = items.sorted { $0.date > $1.date }
    }

    func createGroup(name: String) async throws -> APIGroupWithDetails {
        let created = try await groupService.createGroup(name: name)
        // Wrap in APIGroupWithDetails so the list updates immediately
        let newGroup = APIGroupWithDetails(
            id: created.id,
            name: created.name,
            createdBy: created.createdBy,
            createdAt: created.createdAt,
            members: [],
            balances: []
        )
        groups.insert(newGroup, at: 0)
        return newGroup
    }

    // MARK: - Helpers

    func userBalance(for group: APIGroupWithDetails) -> Double {
        guard let userId = currentUserId else { return 0 }
        let balance = group.balances.first(where: { $0.userId == userId })
        return balance?.amount ?? 0
    }

    func displayName(for member: APIGroupMember) -> String {
        member.username
    }
}
