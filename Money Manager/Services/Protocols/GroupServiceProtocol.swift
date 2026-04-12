//
//  GroupServiceProtocol.swift
//  Money Manager
//

import Foundation

protocol GroupServiceProtocol: Sendable {
    func fetchGroups() async throws -> [APIGroupWithDetails]
    func createGroup(name: String) async throws -> APIGroup
    func fetchGroupDetails(groupId: UUID) async throws -> APIGroupDetails
    func fetchMembers(groupId: UUID) async throws -> [APIGroupMember]
    func addMember(groupId: UUID, email: String) async throws
    func fetchBalances(groupId: UUID) async throws -> [APIGroupBalance]
    func createGroupTransaction(_ request: APICreateGroupTransactionRequest, groupId: UUID) async throws -> APIGroupTransaction
    func fetchGroupTransactions(groupId: UUID) async throws -> [APIGroupTransaction]
    func deleteGroupTransaction(groupId: UUID, transactionId: UUID) async throws
    func createSettlement(_ request: APICreateSettlementRequest) async throws -> APISettlement
}
