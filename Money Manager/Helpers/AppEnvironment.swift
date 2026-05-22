import SwiftUI
import SwiftData

extension EnvironmentValues {
    @Entry var authService: AuthServiceProtocol = AuthService.shared
    @Entry var syncService: SyncServiceProtocol = SyncService.shared
    @Entry var changeQueueManager: ChangeQueueManagerProtocol = ChangeQueueManager.shared
    @Entry var networkMonitor: any NetworkMonitorProtocol = NetworkMonitor.shared
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
