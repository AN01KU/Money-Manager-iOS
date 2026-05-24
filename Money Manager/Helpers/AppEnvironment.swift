import SwiftUI
import SwiftData

// MARK: - AuthService environment key

private struct AuthServiceKey: EnvironmentKey {
    static let defaultValue: any AuthServiceProtocol = {
        #if DEBUG
        return MockAuthService.shared
        #else
        fatalError("AuthService must be injected via .environment(\\.authService, ...) before use")
        #endif
    }()
}

extension EnvironmentValues {
    var authService: any AuthServiceProtocol {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}

// MARK: - ChangeQueueManager environment key

private struct ChangeQueueManagerKey: EnvironmentKey {
    static let defaultValue: any ChangeQueueManagerProtocol = {
        #if DEBUG
        return MockChangeQueueManager.shared
        #else
        fatalError("ChangeQueueManager must be injected via .environment(\\.changeQueueManager, ...) before use")
        #endif
    }()
}

extension EnvironmentValues {
    var changeQueueManager: any ChangeQueueManagerProtocol {
        get { self[ChangeQueueManagerKey.self] }
        set { self[ChangeQueueManagerKey.self] = newValue }
    }
}

// MARK: - NetworkMonitor environment key

private struct NetworkMonitorKey: EnvironmentKey {
    static let defaultValue: any NetworkMonitorProtocol = {
        #if DEBUG
        return MockNetworkMonitor()
        #else
        fatalError("NetworkMonitor must be injected via .environment(\\.networkMonitor, ...) before use")
        #endif
    }()
}

extension EnvironmentValues {
    var networkMonitor: any NetworkMonitorProtocol {
        get { self[NetworkMonitorKey.self] }
        set { self[NetworkMonitorKey.self] = newValue }
    }
}

// MARK: - GroupService environment key

private struct GroupServiceKey: EnvironmentKey {
    static let defaultValue: any GroupServiceProtocol = {
        #if DEBUG
        return MockGroupService.shared
        #else
        fatalError("GroupService must be injected via .environment(\\.groupService, ...) before use")
        #endif
    }()
}

extension EnvironmentValues {
    var groupService: any GroupServiceProtocol {
        get { self[GroupServiceKey.self] }
        set { self[GroupServiceKey.self] = newValue }
    }
}

// MARK: - SyncService environment key

private struct SyncServiceKey: EnvironmentKey {
    static let defaultValue: any SyncServiceProtocol = {
        #if DEBUG
        return MockSyncService.shared
        #else
        fatalError("SyncService must be injected via .environment(\\.syncService, ...) before use")
        #endif
    }()
}

extension EnvironmentValues {
    var syncService: any SyncServiceProtocol {
        get { self[SyncServiceKey.self] }
        set { self[SyncServiceKey.self] = newValue }
    }
}

// MARK: - PersistenceService environment key

private struct PersistenceServiceKey: EnvironmentKey {
    static let defaultValue: PersistenceService = {
        #if DEBUG
        return .testing
        #else
        fatalError("PersistenceService must be injected via .environment(\\.persistence, ...) before use")
        #endif
    }()
}

extension EnvironmentValues {
    var persistence: PersistenceService {
        get { self[PersistenceServiceKey.self] }
        set { self[PersistenceServiceKey.self] = newValue }
    }
}

// MARK: - BudgetRepository environment key

private struct BudgetRepositoryKey: EnvironmentKey {
    static let defaultValue: BudgetRepository = {
        #if DEBUG
        return .testing
        #else
        fatalError("BudgetRepository must be injected via .environment(\\.budgetRepository, ...) before use")
        #endif
    }()
}

extension EnvironmentValues {
    var budgetRepository: BudgetRepository {
        get { self[BudgetRepositoryKey.self] }
        set { self[BudgetRepositoryKey.self] = newValue }
    }
}
