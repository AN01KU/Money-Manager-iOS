//
//  SyncServiceProtocol.swift
//  Money Manager
//

import Foundation
import SwiftData

protocol SyncServiceProtocol: AnyObject {
    var isSyncing: Bool { get }
    var lastSyncedAt: Date? { get }
    var syncSuccessCount: Int { get }
    var syncFailureCount: Int { get }

    func configure(container: ModelContainer)
    func syncOnLaunch() async
    func syncOnReconnect() async
    func fullSync() async
    func bootstrapAfterSignup() async
    func clearGroupData()
    func recordSyncError()
}
