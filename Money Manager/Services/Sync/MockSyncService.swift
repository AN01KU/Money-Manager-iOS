//
//  MockSyncService.swift
//  Money Manager
//

#if DEBUG
import Foundation
import SwiftData

@Observable
final class MockSyncService: SyncServiceProtocol {
    static let shared = MockSyncService()
    
    var isSyncing: Bool = false
    var lastSyncedAt: Date? = Date()
    var syncSuccessCount: Int = 0
    var syncFailureCount: Int = 0
    
    private var modelContainer: ModelContainer?
    
    private init() {}
    
    func configure(container: ModelContainer, authService: AuthServiceProtocol) {
        self.modelContainer = container
    }
    
    func syncOnLaunch() async {}
    
    func syncOnReconnect() async {}
    
    func fullSync() async {
        isSyncing = true
        try? await Task.sleep(nanoseconds: 100_000_000)
        isSyncing = false
        lastSyncedAt = Date()
    }

    func bootstrapAfterSignup() async {}

    func clearGroupData() {}

    func recordSyncError() { syncFailureCount += 1 }
}
#endif
