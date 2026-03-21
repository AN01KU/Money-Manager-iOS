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
            let wasConnected = self?.isConnected ?? false
            let isNowConnected = path.status == .satisfied
            
            DispatchQueue.main.async {
                self?.isConnected = isNowConnected
                
                if !wasConnected && isNowConnected {
                    NotificationCenter.default.post(
                        name: .networkDidBecomeAvailable,
                        object: nil
                    )
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
