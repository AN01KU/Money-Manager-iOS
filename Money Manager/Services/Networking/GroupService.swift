//
//  GroupService.swift
//  Money Manager
//

import Foundation

final class GroupService: GroupServiceProtocol {
    static let shared = GroupService()
    private let apiClient = AppAPIClient.shared

    private init() {}

    func fetchGroups() async throws -> [SplitGroup] {
        let response: APIGroupsListResponse = try await apiClient.get(.groups)
        return response.data.compactMap { try? SplitGroup(from: $0) }
    }

    func createGroup(name: String) async throws -> SplitGroup {
        let request = APICreateGroupRequest(name: name)
        let dto: APIGroup = try await apiClient.post(.groups, body: request)
        return SplitGroup(id: dto.id, name: dto.name, createdBy: dto.createdBy, createdAt: dto.createdAt, members: [], balances: [], settlements: [])
    }

    func renameGroup(groupId: UUID, name: String) async throws -> SplitGroup {
        let request = APIRenameGroupRequest(name: name)
        let dto: APIGroup = try await apiClient.patch(.group(groupId), body: request)
        return SplitGroup(id: dto.id, name: dto.name, createdBy: dto.createdBy, createdAt: dto.createdAt, members: [], balances: [], settlements: [])
    }

    func deleteGroup(groupId: UUID) async throws {
        try await apiClient.delete(.group(groupId))
    }

    func fetchGroupDetails(groupId: UUID) async throws -> SplitGroup {
        let dto: APIGroupDetails = try await apiClient.get(.group(groupId))
        return try SplitGroup(from: dto.group)
    }

    func fetchMembers(groupId: UUID) async throws -> [GroupMember] {
        let response: APIListResponse<APIGroupMember> = try await apiClient.get(.groupMembers(groupId))
        return response.data.map { GroupMember(from: $0) }
    }

    func addMember(groupId: UUID, email: String) async throws {
        let request = APIAddMemberRequest(email: email)
        let _: APIMessageResponse = try await apiClient.post(.groupAddMember(groupId), body: request)
    }

    func removeMember(groupId: UUID, userId: UUID) async throws {
        let _: APIMessageResponse = try await apiClient.deleteMessage(.groupMember(groupId: groupId, userId: userId))
    }

    func leaveGroup(groupId: UUID) async throws {
        let _: APIMessageResponse = try await apiClient.post(.groupLeave(groupId), body: EmptyResponse())
    }

    func fetchBalances(groupId: UUID) async throws -> [GroupBalance] {
        let dtos: [APIGroupBalance] = try await apiClient.get(.groupBalances(groupId))
        return dtos.map { GroupBalance(from: $0) }
    }

    func createGroupTransaction(_ request: APICreateGroupTransactionRequest, groupId: UUID) async throws -> GroupTransaction {
        let dto: APIGroupTransaction = try await apiClient.post(.groupTransactions(groupId), body: request)
        return try GroupTransaction(from: dto)
    }

    func updateGroupTransaction(_ request: APIUpdateGroupTransactionRequest, groupId: UUID, transactionId: UUID) async throws -> GroupTransaction {
        let dto: APIGroupTransaction = try await apiClient.patch(.groupTransaction(groupId: groupId, transactionId: transactionId), body: request)
        return try GroupTransaction(from: dto)
    }

    func fetchGroupTransactions(groupId: UUID) async throws -> [GroupTransaction] {
        let response: APIListResponse<APIGroupTransaction> = try await apiClient.get(.groupTransactions(groupId))
        return response.data.compactMap { try? GroupTransaction(from: $0) }
    }

    func deleteGroupTransaction(groupId: UUID, transactionId: UUID) async throws {
        let _: APIMessageResponse = try await apiClient.deleteMessage(.groupTransaction(groupId: groupId, transactionId: transactionId))
    }

    func createSettlement(_ request: APICreateSettlementRequest) async throws -> Settlement {
        let dto: APISettlement = try await apiClient.post(.settlements, body: request)
        return Settlement(from: dto)
    }

    func deleteSettlement(settlementId: UUID) async throws {
        let _: APIMessageResponse = try await apiClient.deleteMessage(.settlement(settlementId))
    }
}
