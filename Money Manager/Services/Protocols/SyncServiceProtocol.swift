//
//  SyncServiceProtocol.swift
//  Money Manager
//

import Foundation
import SwiftData

protocol SyncServiceProtocol: AnyObject {
    var isSyncing: Bool { get }
    var lastSyncedAt: Date? { get }

    func configure(container: ModelContainer)
    func syncOnLaunch() async
    func syncOnReconnect() async
    func fullSync() async
    func clearGroupData()
}
