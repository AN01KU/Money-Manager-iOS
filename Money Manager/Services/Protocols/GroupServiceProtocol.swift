//
//  GroupServiceProtocol.swift
//  Money Manager
//

import Foundation

protocol GroupServiceProtocol: Sendable {
    func fetchGroups() async throws -> [SplitGroup]
    func createGroup(name: String) async throws -> SplitGroup
    func renameGroup(groupId: UUID, name: String) async throws -> SplitGroup
    func deleteGroup(groupId: UUID) async throws
    func fetchGroupDetails(groupId: UUID) async throws -> SplitGroup
    func fetchMembers(groupId: UUID) async throws -> [GroupMember]
    func addMember(groupId: UUID, email: String) async throws
    func removeMember(groupId: UUID, userId: UUID) async throws
    func leaveGroup(groupId: UUID) async throws
    func fetchBalances(groupId: UUID) async throws -> [GroupBalance]
    func createGroupTransaction(_ request: APICreateGroupTransactionRequest, groupId: UUID) async throws -> GroupTransaction
    func updateGroupTransaction(_ request: APIUpdateGroupTransactionRequest, groupId: UUID, transactionId: UUID) async throws -> GroupTransaction
    func fetchGroupTransactions(groupId: UUID) async throws -> [GroupTransaction]
    func deleteGroupTransaction(groupId: UUID, transactionId: UUID) async throws
    func createSettlement(_ request: APICreateSettlementRequest) async throws -> Settlement
    func deleteSettlement(settlementId: UUID) async throws
}
