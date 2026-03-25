//
//  GroupsListViewModel.swift
//  Money Manager
//

import SwiftUI

enum GroupsTab {
    case groups
    case activities
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

    private let groupService: GroupServiceProtocol

    init(groupService: GroupServiceProtocol = GroupService.shared) {
        self.groupService = groupService
    }

    // MARK: - Computed

    var currentUserId: UUID? {
        authService.currentUser?.id
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
            let balance = group.balances.first(where: { $0.user_id == userId })
            return total + (Double(balance?.amount ?? "0") ?? 0)
        }
    }

    var recentActivity: [(expense: APIGroupExpense, groupName: String)] = []

    var filteredActivity: [(expense: APIGroupExpense, groupName: String)] {
        guard !searchText.isEmpty else { return recentActivity }
        let query = searchText.lowercased()
        return recentActivity.filter {
            $0.groupName.lowercased().contains(query) ||
            $0.expense.description.lowercased().contains(query)
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
        var activity: [(expense: APIGroupExpense, groupName: String)] = []
        await withTaskGroup(of: (String, [APIGroupExpense]).self) { taskGroup in
            for group in groups {
                taskGroup.addTask {
                    let expenses = (try? await self.groupService.fetchGroupDetails(groupId: group.id))?.group.expenses ?? []
                    return (group.name, expenses)
                }
            }
            for await (groupName, expenses) in taskGroup {
                for expense in expenses {
                    activity.append((expense: expense, groupName: groupName))
                }
            }
        }
        recentActivity = activity.sorted { $0.expense.created_at > $1.expense.created_at }
    }

    func createGroup(name: String) async throws -> APIGroupWithDetails {
        let created = try await groupService.createGroup(name: name)
        // Wrap in APIGroupWithDetails so the list updates immediately
        let newGroup = APIGroupWithDetails(
            id: created.id,
            name: created.name,
            created_by: created.created_by,
            created_at: created.created_at,
            members: [],
            balances: []
        )
        groups.insert(newGroup, at: 0)
        return newGroup
    }

    // MARK: - Helpers

    func userBalance(for group: APIGroupWithDetails) -> Double {
        guard let userId = currentUserId else { return 0 }
        let balance = group.balances.first(where: { $0.user_id == userId })
        return Double(balance?.amount ?? "0") ?? 0
    }

    func displayName(for member: APIGroupMember) -> String {
        member.email.components(separatedBy: "@").first?.capitalized ?? member.email
    }
}
