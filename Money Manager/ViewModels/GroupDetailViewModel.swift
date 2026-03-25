//
//  GroupDetailViewModel.swift
//  Money Manager
//

import SwiftUI

enum GroupSection: String, CaseIterable {
    case expenses = "Expenses"
    case balances = "Balances"
    case members  = "Members"
}

@MainActor
@Observable
final class GroupDetailViewModel {
    var group: APIGroupWithDetails
    var expenses: [APIGroupExpense] = []
    var members: [APIGroupMember] = []
    var balances: [APIGroupBalance] = []
    var isLoading = false
    var selectedSection: GroupSection = .expenses

    // Errors
    var errorMessage: String?
    var showError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    // Add member
    var showAddMember = false
    var addMemberError: String?
    var showAddMemberError: Bool {
        get { addMemberError != nil }
        set { if !newValue { addMemberError = nil } }
    }
    var pendingMemberEmails: Set<String> = []

    // Add expense / settle
    var showAddExpense = false
    var showSettlement = false

    let groupService: GroupServiceProtocol

    init(group: APIGroupWithDetails, groupService: GroupServiceProtocol = GroupService.shared) {
        self.group = group
        self.members = group.members
        self.balances = group.balances
        self.groupService = groupService
    }

    // MARK: - Computed

    var currentUserId: UUID? {
        authService.currentUser?.id
    }

    var groupTotal: Double {
        expenses.compactMap { Double($0.total_amount) }.reduce(0, +)
    }

    var hasUnsettledBalances: Bool {
        balances.contains { (Double($0.amount) ?? 0) != 0 }
    }

    // MARK: - Load

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            let details = try await groupService.fetchGroupDetails(groupId: group.id)
            expenses = details.group.expenses
            members  = details.group.members
            balances = details.group.balances
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Add Member (optimistic, invite semantics)

    func addMember(email: String) {
        let trimmed = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return }
        guard !members.contains(where: { $0.email.lowercased() == trimmed }) else { return }

        // Optimistic placeholder
        pendingMemberEmails.insert(trimmed)
        showAddMember = false

        Task {
            do {
                try await groupService.addMember(groupId: group.id, email: trimmed)
                // Refresh members from server to get real ID
                let updated = try await groupService.fetchMembers(groupId: group.id)
                members = updated
            } catch {
                addMemberError = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
            pendingMemberEmails.remove(trimmed)
        }
    }

    // MARK: - After expense added

    func expenseAdded(_ expense: APIGroupExpense) {
        expenses.insert(expense, at: 0)
        recalculateBalances()
    }

    // MARK: - After settlement recorded

    func settlementRecorded(_ settlement: APISettlement) {
        recalculateBalances()
    }

    // MARK: - Helpers

    func displayName(for member: APIGroupMember) -> String {
        member.email.components(separatedBy: "@").first?.capitalized ?? member.email
    }

    func displayName(forId userId: UUID) -> String {
        guard let member = members.first(where: { $0.id == userId }) else { return "Unknown" }
        return displayName(for: member)
    }

    func isPending(_ member: APIGroupMember) -> Bool {
        pendingMemberEmails.contains(member.email.lowercased())
    }

    // MARK: - Private

    private func recalculateBalances() {
        var map: [UUID: Double] = [:]
        for m in members { map[m.id] = 0 }

        for expense in expenses {
            map[expense.paid_by, default: 0] += Double(expense.total_amount) ?? 0
        }

        // Split equally among all members for now (server is authoritative for custom splits)
        let memberCount = members.isEmpty ? 1 : members.count
        for expense in expenses {
            let share = (Double(expense.total_amount) ?? 0) / Double(memberCount)
            for m in members {
                map[m.id, default: 0] -= share
            }
        }

        balances = map.map { APIGroupBalance(user_id: $0.key, amount: String(format: "%.2f", $0.value)) }
    }
}
