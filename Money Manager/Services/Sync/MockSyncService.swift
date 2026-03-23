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
    
    private var modelContainer: ModelContainer?
    
    private init() {}
    
    func configure(container: ModelContainer) {
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
}
#endif
