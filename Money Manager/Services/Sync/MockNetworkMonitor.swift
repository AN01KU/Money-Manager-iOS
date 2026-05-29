//
//  MockNetworkMonitor.swift
//  Money Manager
//

#if DEBUG
import Foundation

@Observable
final class MockNetworkMonitor: NetworkMonitorProtocol {
    var isConnected: Bool

    init(isConnected: Bool = true) {
        self.isConnected = isConnected
    }
}
#endif
