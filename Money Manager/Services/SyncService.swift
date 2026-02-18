//
//  SyncService.swift
//  Money Manager
//
//  Handles background sync of offline data with server
//

import Foundation
import SwiftData
import Network
import Combine

@MainActor
final class SyncService: ObservableObject {
    static let shared = SyncService()
    
    @Published private(set) var isSyncing = false
    @Published private(set) var pendingCount = 0
    @Published private(set) var isConnected = true
    @Published private(set) var lastSyncDate: Date?
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var modelContext: ModelContext?
    
    private init() {
        setupNetworkMonitoring()
    }
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        Task { @MainActor in
            self.updatePendingCount()
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self else { return }
                self.isConnected = path.status == .satisfied
                if path.status == .satisfied {
                    await self.syncPendingItems()
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    nonisolated func queueForSync(itemType: PendingSyncItem.ItemType, itemId: UUID, action: PendingSyncItem.Action, payload: Encodable) {
        Task { @MainActor in
            self.performQueueForSync(itemType: itemType, itemId: itemId, action: action, payload: payload)
        }
    }
    
    private func performQueueForSync(itemType: PendingSyncItem.ItemType, itemId: UUID, action: PendingSyncItem.Action, payload: Encodable) {
        guard let modelContext = modelContext else { return }
        
        do {
            let encoder = JSONEncoder()
            let payloadData = try encoder.encode(payload)
            
            let syncItem = PendingSyncItem(
                itemType: itemType,
                itemId: itemId,
                action: action,
                payload: payloadData
            )
            
            modelContext.insert(syncItem)
            try modelContext.save()
            updatePendingCount()
            
            if isConnected {
                Task {
                    await syncPendingItems()
                }
            }
        } catch {
            print("Failed to queue item for sync: \(error)")
        }
    }
    
    func syncPendingItems() async {
        guard isConnected, !isSyncing else { return }
        guard let modelContext = modelContext else { return }
        
        isSyncing = true
        
        let descriptor = FetchDescriptor<PendingSyncItem>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        do {
            let pendingItems = try modelContext.fetch(descriptor)
            
            for item in pendingItems {
                do {
                    try await syncItem(item)
                    modelContext.delete(item)
                    try modelContext.save()
                } catch {
                    item.retryCount += 1
                    item.lastError = error.localizedDescription
                    try? modelContext.save()
                }
            }
            
            lastSyncDate = Date()
            updatePendingCount()
        } catch {
            print("Failed to fetch pending items: \(error)")
        }
        
        isSyncing = false
    }
    
    private func syncItem(_ item: PendingSyncItem) async throws {
        guard let itemType = PendingSyncItem.ItemType(rawValue: item.itemType),
              let action = PendingSyncItem.Action(rawValue: item.action) else {
            throw SyncError.invalidItem
        }
        
        switch (itemType, action) {
        case (.personalExpense, .create):
            try await syncPersonalExpense(item)
        case (.sharedExpense, .create):
            try await syncSharedExpense(item)
        case (.budget, .create), (.budget, .update):
            try await syncBudget(item)
        case (.category, .create), (.category, .update):
            try await syncCategory(item)
        case (.personalExpense, .delete):
            try await deletePersonalExpense(item)
        default:
            throw SyncError.unsupportedOperation
        }
    }
    
    private func syncPersonalExpense(_ item: PendingSyncItem) async throws {
        let decoder = JSONDecoder()
        let request = try decoder.decode(CreatePersonalExpenseRequest.self, from: item.payload)
        _ = try await APIService.shared.createPersonalExpense(request)
    }
    
    private func syncSharedExpense(_ item: PendingSyncItem) async throws {
        let decoder = JSONDecoder()
        let request = try decoder.decode(CreateSharedExpenseRequest.self, from: item.payload)
        _ = try await APIService.shared.createExpense(request)
    }
    
    private func syncBudget(_ item: PendingSyncItem) async throws {
        let decoder = JSONDecoder()
        let request = try decoder.decode(SetBudgetRequest.self, from: item.payload)
        _ = try await APIService.shared.setBudget(amount: Double(request.amount) ?? 0, month: request.month, year: request.year)
    }
    
    private func syncCategory(_ item: PendingSyncItem) async throws {
        let decoder = JSONDecoder()
        let request = try decoder.decode(CreateCategoryRequest.self, from: item.payload)
        _ = try await APIService.shared.createCategory(name: request.name, color: request.color, icon: request.icon)
    }
    
    private func deletePersonalExpense(_ item: PendingSyncItem) async throws {
        _ = try await APIService.shared.deletePersonalExpense(id: item.itemId)
    }
    
    private func updatePendingCount() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<PendingSyncItem>()
        pendingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    func triggerManualSync() {
        Task {
            await syncPendingItems()
        }
    }
}

enum SyncError: LocalizedError {
    case invalidItem
    case unsupportedOperation
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidItem:
            return "Invalid sync item"
        case .unsupportedOperation:
            return "This operation is not yet supported for sync"
        case .networkUnavailable:
            return "No network connection available"
        }
    }
}
