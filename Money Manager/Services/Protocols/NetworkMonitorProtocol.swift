//
//  NetworkMonitorProtocol.swift
//  Money Manager
//

import Foundation

protocol NetworkMonitorProtocol: AnyObject, Observable {
    @MainActor var isConnected: Bool { get }
}
