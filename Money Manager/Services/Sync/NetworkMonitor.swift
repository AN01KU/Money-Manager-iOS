//
//  NetworkMonitor.swift
//  Money Manager
//

import Foundation
import Network

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    var isConnected: Bool = false
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        monitor = NWPathMonitor()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isNowConnected = path.status == .satisfied
            DispatchQueue.main.async {
                let wasConnected = self?.isConnected ?? false
                self?.isConnected = isNowConnected
                if !wasConnected && isNowConnected {
                    AppLogger.sync.info("Network became available — triggering reconnect sync")
                    NotificationCenter.default.post(name: .networkDidBecomeAvailable, object: nil)
                } else if wasConnected && !isNowConnected {
                    AppLogger.sync.info("Network lost")
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}

extension Notification.Name {
    static let networkDidBecomeAvailable = Notification.Name("networkDidBecomeAvailable")
}
