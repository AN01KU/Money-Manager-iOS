import SwiftUI

extension EnvironmentValues {
    @Entry var authService: AuthServiceProtocol = AuthService.shared
    @Entry var syncService: SyncServiceProtocol = SyncService.shared
    @Entry var changeQueueManager: ChangeQueueManagerProtocol = ChangeQueueManager.shared
}
