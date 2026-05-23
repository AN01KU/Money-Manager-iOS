import SwiftUI
import SwiftData

extension EnvironmentValues {
    @Entry var authService: AuthServiceProtocol = AuthService.shared
    @Entry var changeQueueManager: ChangeQueueManagerProtocol = ChangeQueueManager.shared
    @Entry var networkMonitor: any NetworkMonitorProtocol = NetworkMonitor.shared
    @Entry var groupService: GroupServiceProtocol = GroupService.shared
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
