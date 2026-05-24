//
//  SyncService.swift
//  Money Manager
//

import Foundation
import SwiftData

enum PreflightOutcome {
    case valid
    case invalid(reason: String)
    case skipped   // no session ID — offline queue was created before any login
}

@Observable
@MainActor
final class SyncService: SyncServiceProtocol {
    #if DEBUG
    static let shared = SyncService()
    #endif

    var isSyncing: Bool = false
    var lastSyncedAt: Date?
    var syncSuccessCount: Int = 0
    var syncFailureCount: Int = 0

    let apiClient: any APIClientProtocol
    private let groupService: GroupServiceProtocol
    let networkMonitor: any NetworkMonitorProtocol
    private let authService: AuthServiceProtocol
    private let modelContainer: ModelContainer
    private let changeQueue: any ChangeQueueManagerProtocol

    private let lastSyncKey = UserDefaults.Keys.lastSyncAt.rawValue
    nonisolated(unsafe) private var networkObserver: Any?
    nonisolated(unsafe) private var logoutObserver: Any?
    nonisolated(unsafe) private var switchAccountObserver: Any?

    #if DEBUG
    private convenience init() {
        let schema = Schema([
            Transaction.self, RecurringTransaction.self, UserBudget.self, Category.self,
            PendingChange.self, FailedChange.self, OrphanedChange.self,
            SplitGroupModel.self, GroupMemberModel.self, GroupTransactionModel.self, GroupBalanceModel.self
        ])
        let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        self.init(
            api: AppAPIClient.shared,
            changeQueue: ChangeQueueManager.shared,
            networkMonitor: NetworkMonitor.shared,
            authService: MockAuthService.shared,
            container: container
        )
    }
    #endif

    init(
        api: any APIClientProtocol,
        changeQueue: any ChangeQueueManagerProtocol,
        networkMonitor: any NetworkMonitorProtocol,
        authService: AuthServiceProtocol,
        container: ModelContainer,
        groupService: GroupServiceProtocol = GroupService.shared
    ) {
        self.apiClient = api
        self.changeQueue = changeQueue
        self.networkMonitor = networkMonitor
        self.authService = authService
        self.modelContainer = container
        self.groupService = groupService
        lastSyncedAt = UserDefaults.standard.object(forKey: lastSyncKey) as? Date

        changeQueue.configure(container: container)

        networkObserver = NotificationCenter.default.addObserver(
            forName: .networkDidBecomeAvailable,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.authService.isAuthenticated else { return }
                await self.syncOnReconnect()
            }
        }

        logoutObserver = NotificationCenter.default.addObserver(
            forName: .userDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.clearGroupData()
            }
        }

        switchAccountObserver = NotificationCenter.default.addObserver(
            forName: .userDidSwitchAccount,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.clearAllUserData()
            }
        }
    }

    deinit {
        if let observer = networkObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = logoutObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = switchAccountObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func clearGroupData() {
        LocalDataWiper.groupData.wipe(context: ModelContext(modelContainer))
    }

    func clearAllUserData() {
        LocalDataWiper.allUserData.wipe(context: ModelContext(modelContainer))
        for key: UserDefaults.Keys in [.lastSyncAt, .selectedCurrency, .defaultBudgetLimit, .userTimezone] {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }
    
    func syncOnLaunch() async {
        guard authService.isAuthenticated else { return }

        AppLogger.sync.info("Sync on launch started")
        let context = ModelContext(modelContainer)

        changeQueue.purgeExpiredOrphans(olderThan: 7, context: context)

        let preflight = await runPreflight()
        switch preflight {
        case .valid:
            await changeQueue.replayAll(context: context, isAuthenticated: true)
        case .skipped:
            AppLogger.sync.info("Preflight skipped (no sync session) — not replaying queue")
        case .invalid(let reason):
            AppLogger.sync.warning("Preflight failed on launch: \(reason) — orphaning queue")
            changeQueue.orphanAll(context: context)
            SessionStore.shared.clearSyncSessionID()
            NotificationCenter.default.post(name: .syncSessionOrphaned, object: nil)
        }

        await pullFromServer(context: context)
        AppLogger.sync.info("Sync on launch complete")
    }

    func syncOnReconnect() async {
        guard networkMonitor.isConnected else { return }

        isSyncing = true
        defer { isSyncing = false }

        AppLogger.sync.info("Sync on reconnect started")
        let context = ModelContext(modelContainer)

        let preflight = await runPreflight()
        switch preflight {
        case .valid:
            await changeQueue.replayAll(context: context, isAuthenticated: authService.isAuthenticated)
        case .skipped:
            AppLogger.sync.info("Preflight skipped (no sync session) — not replaying queue")
        case .invalid(let reason):
            AppLogger.sync.warning("Preflight failed on reconnect: \(reason) — orphaning queue")
            changeQueue.orphanAll(context: context)
            SessionStore.shared.clearSyncSessionID()
            NotificationCenter.default.post(name: .syncSessionOrphaned, object: nil)
        }

        await pullFromServer(context: context)
        AppLogger.sync.info("Sync on reconnect complete")
    }

    /// Calls POST /sync/preflight to verify the stored sync session is still valid.
    /// Returns `.skipped` when no session ID is stored (nothing queued offline yet).
    private func runPreflight() async -> PreflightOutcome {
        guard let sessionID = SessionStore.shared.getSyncSessionID() else {
            return .skipped
        }

        do {
            let body = APISyncPreflightRequest(syncSessionId: sessionID)
            let response: APISyncPreflightResponse = try await apiClient.post(.syncPreflight, body: body)
            return response.valid ? .valid : .invalid(reason: response.reason ?? "UNKNOWN")
        } catch let error as APIError {
            if case .syncSessionInvalid(let reason) = error {
                return .invalid(reason: reason)
            }
            // Network or server error — treat as skipped so we don't block the queue unnecessarily
            AppLogger.sync.warning("Preflight request failed: \(error) — proceeding with sync")
            return .skipped
        } catch {
            AppLogger.sync.warning("Preflight request failed: \(error) — proceeding with sync")
            return .skipped
        }
    }

    func fullSync() async {
        isSyncing = true
        defer { isSyncing = false }

        AppLogger.sync.info("Full sync started")
        let context = ModelContext(modelContainer)

        await pullFromServer(context: context)
        updateLastSyncTime()
        syncSuccessCount += 1
        AppLogger.sync.info("Full sync complete")
    }

    func bootstrapAfterSignup() async {
        isSyncing = true
        defer { isSyncing = false }

        AppLogger.sync.info("Bootstrap after signup started")
        let context = ModelContext(modelContainer)

        // 1. Enqueue all local user data as creates
        enqueueLocalData(context: context)

        // 2. Push everything to server
        await changeQueue.replayAll(context: context, isAuthenticated: authService.isAuthenticated)

        // 3. Pull canonical state
        await pullFromServer(context: context)
        updateLastSyncTime()
        AppLogger.sync.info("Bootstrap after signup complete")
    }

    private func enqueueLocalData(context: ModelContext) {
        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        for tx in transactions where !tx.isSoftDeleted {
            guard let payload = try? AppAPIClient.apiEncoder.encode(tx.toCreateRequest()) else { continue }
            changeQueue.enqueue(
                PendingChangeDraft(entityType: .transaction, entityID: tx.id, action: .create,
                                   endpoint: "/transactions", httpMethod: .post, payload: payload),
                context: context
            )
        }

        let categories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let customOnly = categories.filter { !$0.isPredefined }
        AppLogger.sync.debug("[EnqueueLocalData] total Category rows=\(categories.count) uploading custom-only=\(customOnly.count)")
        for cat in customOnly {
            guard let payload = try? AppAPIClient.apiEncoder.encode(cat.toCreateRequest()) else { continue }
            changeQueue.enqueue(
                PendingChangeDraft(entityType: .category, entityID: cat.id, action: .create,
                                   endpoint: "/categories", httpMethod: .post, payload: payload),
                context: context
            )
        }

        if let budget = (try? context.fetch(FetchDescriptor<UserBudget>()))?.first, budget.limit != nil {
            if let payload = try? AppAPIClient.apiEncoder.encode(APISetBudgetRequest(limit: budget.limit)) {
                changeQueue.enqueue(
                    PendingChangeDraft(entityType: .budget, entityID: budget.id, action: .create,
                                       endpoint: "/me/budget", httpMethod: .put, payload: payload),
                    context: context
                )
            }
        }

        let recurringItems = (try? context.fetch(FetchDescriptor<RecurringTransaction>())) ?? []
        for item in recurringItems where !item.isSoftDeleted {
            guard let payload = try? AppAPIClient.apiEncoder.encode(item.toCreateRequest()) else { continue }
            changeQueue.enqueue(
                PendingChangeDraft(entityType: .recurring, entityID: item.id, action: .create,
                                   endpoint: "/recurring-transactions", httpMethod: .post, payload: payload),
                context: context
            )
        }
    }
    
    // MARK: - Pull Pipeline

    private let pullHandlers: [any PullEntityHandler] = [
        PredefinedCategoryPullHandler(),
        UserBudgetPullHandler(),
        RecurringTransactionPullHandler(),
        TransactionPullHandler(),
        CategoryPullHandler()
    ]

    private func runPullPipeline(context: ModelContext) async {
        for handler in pullHandlers {
            do {
                try await handler.pull(api: apiClient, changeQueue: changeQueue, context: context)
                syncCheckpoint(
                    entityType: handler.entityLabel,
                    serverCount: handler.lastServerCount,
                    localCount: handler.lastLocalCount
                )
            } catch {
                AppLogger.sync.error("Failed to pull \(handler.entityLabel): \(error)")
                recordSyncError()
            }
        }
    }

    private func pullFromServer(context: ModelContext) async {
        isSyncing = true
        defer { isSyncing = false }

        await runPullPipeline(context: context)

        updateLastSyncTime()
    }

    func bootstrapPredefinedCategories() async {
        let context = ModelContext(modelContainer)
        let handler = PredefinedCategoryPullHandler()
        do {
            try await handler.pull(api: apiClient, changeQueue: changeQueue, context: context)
            AppLogger.sync.info("Bootstrapped \(handler.lastServerCount) predefined categories")
        } catch {
            AppLogger.sync.error("Failed to fetch predefined categories: \(error)")
        }
    }

    private func pullGroups(context: ModelContext) async {
        do {
            let groups = try await groupService.fetchGroups()
            await upsertGroups(groups, context: context)
        } catch {
            AppLogger.sync.error("Failed to pull groups: \(error)")
        }
    }

    private func upsertGroups(_ apiGroups: [SplitGroup], context: ModelContext) async {
        // Fetch all existing local models
        let localGroups = (try? context.fetch(FetchDescriptor<SplitGroupModel>())) ?? []
        let localGroupsByID = Dictionary(uniqueKeysWithValues: localGroups.map { ($0.id, $0) })

        let localMembers = (try? context.fetch(FetchDescriptor<GroupMemberModel>())) ?? []
        let localMembersByID = Dictionary(uniqueKeysWithValues: localMembers.map { ($0.id, $0) })

        let localGroupTransactions = (try? context.fetch(FetchDescriptor<GroupTransactionModel>())) ?? []
        let localGroupTransactionsByID = Dictionary(uniqueKeysWithValues: localGroupTransactions.map { ($0.id, $0) })

        for remote in apiGroups {
            // Upsert group
            let dbGroup: SplitGroupModel
            if let existing = localGroupsByID[remote.id] {
                existing.name = remote.name
                dbGroup = existing
            } else {
                let newGroup = SplitGroupModel(
                    id: remote.id,
                    name: remote.name,
                    createdBy: remote.createdBy,
                    createdAt: remote.createdAt
                )
                context.insert(newGroup)
                dbGroup = newGroup
            }

            // Upsert members
            for member in remote.members {
                if localMembersByID[member.id] == nil {
                    let newMember = GroupMemberModel(
                        id: member.id,
                        email: member.email,
                        username: member.username,
                        joinedAt: member.joinedAt ?? Date()
                    )
                    newMember.group = dbGroup
                    context.insert(newMember)
                }
            }

            // Upsert balances — replace all for this group
            let existingBalances = (try? context.fetch(
                FetchDescriptor<GroupBalanceModel>()
            ))?.filter { $0.group?.id == remote.id } ?? []
            for b in existingBalances { context.delete(b) }

            for balance in remote.balances {
                let newBalance = GroupBalanceModel(userId: balance.userId, amount: balance.amount)
                newBalance.group = dbGroup
                context.insert(newBalance)
            }
        }

        try? context.save()

        // Sync group transactions separately (not included in list response)
        for remote in apiGroups {
            await pullGroupTransactions(groupId: remote.id, dbGroupId: remote.id, localGroupTransactionsByID: localGroupTransactionsByID, context: context)
        }
    }

    private func pullGroupTransactions(
        groupId: UUID,
        dbGroupId: UUID,
        localGroupTransactionsByID: [UUID: GroupTransactionModel],
        context: ModelContext
    ) async {
        do {
            let remote = try await groupService.fetchGroupTransactions(groupId: groupId)
            AppLogger.sync.debug("pullGroupTransactions: group=\(groupId) fetched \(remote.count) transactions")

            let localGroups = (try? context.fetch(FetchDescriptor<SplitGroupModel>())) ?? []
            guard let dbGroup = localGroups.first(where: { $0.id == dbGroupId }) else {
                AppLogger.sync.warning("pullGroupTransactions: SplitGroupModel not found for id=\(dbGroupId)")
                return
            }

            for gt in remote where !gt.isDeleted {
                if let existing = localGroupTransactionsByID[gt.id] {
                    existing.transactionDescription = gt.description ?? ""
                    existing.totalAmount = gt.totalAmount
                } else {
                    let newGT = GroupTransactionModel(
                        id: gt.id,
                        description: gt.description ?? "",
                        totalAmount: gt.totalAmount,
                        paidBy: gt.paidByUserId,
                        createdAt: gt.createdAt
                    )
                    newGT.group = dbGroup
                    context.insert(newGT)
                }
            }

            try? context.save()
        } catch {
            AppLogger.sync.error("pullGroupTransactions failed for group=\(groupId): \(error)")
        }
    }

    // MARK: - Sync Checkpoint

    private func syncCheckpoint(entityType: String, serverCount: Int, localCount: Int) {
        let delta = abs(serverCount - localCount)
        if delta > 10 && localCount > 0 {
            AppLogger.sync.warning("Sync checkpoint: \(entityType) divergence — server=\(serverCount) local=\(localCount) delta=\(delta)")
        } else {
            AppLogger.sync.debug("Sync checkpoint: \(entityType) ok — server=\(serverCount) local=\(localCount)")
        }
    }

    private func updateLastSyncTime() {
        lastSyncedAt = Date()
        UserDefaults.standard.set(lastSyncedAt, forKey: lastSyncKey)
    }

    func recordSyncError() {
        syncFailureCount += 1
    }
}
