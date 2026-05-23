//
//  SyncServiceProtocol.swift
//  Money Manager
//

import Foundation

protocol SyncServiceProtocol: AnyObject {
    var isSyncing: Bool { get }
    var lastSyncedAt: Date? { get }
    var syncSuccessCount: Int { get }
    var syncFailureCount: Int { get }

    func bootstrapPredefinedCategories() async
    func syncOnLaunch() async
    func syncOnReconnect() async
    func fullSync() async
    func bootstrapAfterSignup() async
    func clearGroupData()
    func clearAllUserData()
    func recordSyncError()
}
