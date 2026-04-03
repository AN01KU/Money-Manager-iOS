//
//  GroupDetailViewModel.swift
//  Money Manager
//

import SwiftUI

enum GroupSection: String, CaseIterable {
    case transactions = "Transactions"
    case balances     = "Balances"
    case members      = "Members"
}

struct PairwiseDebt: Identifiable {
    let id = UUID()
    let fromUserId: UUID
    let toUserId: UUID
    let amount: Double
}

@MainActor
@Observable
final class GroupDetailViewModel {
    var group: APIGroupWithDetails
    var transactions: [APIGroupTransaction] = []
    var members: [APIGroupMember] = []
    var balances: [APIGroupBalance] = []
    var settlements: [APISettlement] = []
    var isLoading = false
    var selectedSection: GroupSection = .transactions

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

    // Add transaction / settle
    var showAddTransaction = false
    var showSettlement = false

    let groupService: GroupServiceProtocol
    let currentUserId: UUID?

    init(group: APIGroupWithDetails, groupService: GroupServiceProtocol = GroupService.shared, currentUserId: UUID? = nil) {
        self.group = group
        self.members = group.members
        self.balances = group.balances
        self.groupService = groupService
        self.currentUserId = currentUserId
    }

    var groupTotal: Double {
        transactions.compactMap { Double($0.total_amount) }.reduce(0, +)
    }

    var hasUnsettledBalances: Bool {
        balances.contains { (Double($0.amount) ?? 0) != 0 }
    }

    /// Pairwise debts derived from backend net balances.
    /// Backend: positive = is owed (paid more), negative = owes (paid less).
    /// Pairs each debtor with a creditor to produce "X owes Y — amount" rows.
    var pairwiseDebts: [PairwiseDebt] {
        var debtors: [(userId: UUID, amount: Double)] = []
        var creditors: [(userId: UUID, amount: Double)] = []

        for b in balances {
            let amt = Double(b.amount) ?? 0
            if amt < 0 {
                debtors.append((b.user_id, abs(amt)))
            } else if amt > 0 {
                creditors.append((b.user_id, amt))
            }
        }

        debtors.sort { $0.amount > $1.amount }
        creditors.sort { $0.amount > $1.amount }

        var result: [PairwiseDebt] = []
        var di = 0, ci = 0
        while di < debtors.count && ci < creditors.count {
            let amount = min(debtors[di].amount, creditors[ci].amount)
            if amount > 0.01 {
                result.append(PairwiseDebt(
                    fromUserId: debtors[di].userId,
                    toUserId: creditors[ci].userId,
                    amount: amount
                ))
            }
            debtors[di].amount -= amount
            creditors[ci].amount -= amount
            if debtors[di].amount < 0.01 { di += 1 }
            if creditors[ci].amount < 0.01 { ci += 1 }
        }
        return result
    }

    // MARK: - Load

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            let details = try await groupService.fetchGroupDetails(groupId: group.id)
            transactions = try await groupService.fetchGroupTransactions(groupId: group.id)
            members     = details.group.members
            balances    = details.group.balances
            settlements = details.group.settlements ?? []
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

    // MARK: - After transaction added / edited

    func transactionAdded(_ transaction: APIGroupTransaction) {
        transactions.insert(transaction, at: 0)
        recalculateBalances()
    }

    func transactionEdited(replacing old: APIGroupTransaction, with updated: APIGroupTransaction) {
        if let idx = transactions.firstIndex(where: { $0.id == old.id }) {
            transactions[idx] = updated
        } else {
            transactions.insert(updated, at: 0)
        }
        recalculateBalances()

        Task {
            do {
                try await groupService.deleteGroupTransaction(groupId: group.id, transactionId: old.id)
            } catch {
                // Restore old on failure
                if let idx = transactions.firstIndex(where: { $0.id == updated.id }) {
                    transactions[idx] = old
                }
                recalculateBalances()
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    // MARK: - Delete transaction

    func deleteTransaction(_ transaction: APIGroupTransaction) {
        transactions.removeAll { $0.id == transaction.id }
        recalculateBalances()

        Task {
            do {
                try await groupService.deleteGroupTransaction(groupId: group.id, transactionId: transaction.id)
            } catch {
                // Restore on failure
                transactions.insert(transaction, at: 0)
                recalculateBalances()
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    // MARK: - After settlement recorded

    func settlementRecorded(_ settlement: APISettlement) {
        settlements.insert(settlement, at: 0)
        Task { await loadData() }
    }

    // MARK: - Helpers

    func displayName(for member: APIGroupMember) -> String {
        member.username
    }

    func displayName(forId userId: UUID) -> String {
        members.first(where: { $0.id == userId })?.username ?? "Unknown"
    }

    func isPending(_ member: APIGroupMember) -> Bool {
        pendingMemberEmails.contains(member.email.lowercased())
    }

    // MARK: - Private

    private func recalculateBalances() {
        var map: [UUID: Double] = [:]
        for m in members { map[m.id] = 0 }

        for tx in transactions {
            map[tx.paid_by_user_id, default: 0] += Double(tx.total_amount) ?? 0
        }

        // Split equally among all members for now (server is authoritative for custom splits)
        let memberCount = members.isEmpty ? 1 : members.count
        for tx in transactions {
            let share = (Double(tx.total_amount) ?? 0) / Double(memberCount)
            for m in members {
                map[m.id, default: 0] -= share
            }
        }

        balances = map.map { APIGroupBalance(user_id: $0.key, amount: String(format: "%.2f", $0.value)) }
    }
}
