//
//  ServiceFactory.swift
//  Money Manager
//

import Foundation

struct ServiceFactory {
    private let useMocks: Bool
    private let isRunningTests: Bool
    
    init(_ useMocks: Bool) {
        self.useMocks = useMocks
        self.isRunningTests = ProcessInfo.processInfo.isRunningTests
    }
    
    private(set) lazy var authService: AuthServiceProtocol = {
        #if DEBUG
        if useMocks || isRunningTests {
            return MockAuthService.shared
        }
        #endif
        return AuthService.shared
    }()
    
    private(set) lazy var syncService: SyncServiceProtocol = {
        #if DEBUG
        if useMocks || isRunningTests {
            return MockSyncService.shared
        }
        #endif
        return SyncService.shared
    }()
    
    private(set) lazy var changeQueueManager: ChangeQueueManagerProtocol = {
        #if DEBUG
        if useMocks || isRunningTests {
            return MockChangeQueueManager.shared
        }
        #endif
        return ChangeQueueManager.shared
    }()
}
