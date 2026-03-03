//
//  SyncService.swift
//  Money Manager
//
//  Handles background sync of offline data with server.
//  Debounces sync scheduling, rate-limits requests, and retries
//  with exponential backoff to avoid spamming the backend.
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
    @Published private(set) var failedCount = 0
    @Published private(set) var isConnected = true
    @Published private(set) var lastSyncDate: Date?
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var modelContext: ModelContext?
    private var debounceTask: Task<Void, Never>?
    
    let maxRetryCount: Int
    let debounceInterval: TimeInterval
    let itemDelay: TimeInterval
    
    init(
        maxRetryCount: Int = 5,
        debounceInterval: TimeInterval = 2.0,
        itemDelay: TimeInterval = 0.5
    ) {
        self.maxRetryCount = maxRetryCount
        self.debounceInterval = debounceInterval
        self.itemDelay = itemDelay
    }
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        updateCounts()
        setupNetworkMonitoring()
        scheduleSyncIfNeeded()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self else { return }
                let wasConnected = self.isConnected
                self.isConnected = path.status == .satisfied
                if !wasConnected && self.isConnected {
                    self.scheduleSyncIfNeeded()
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    // MARK: - Queuing
    
    nonisolated func queueForSync(
        itemType: PendingSyncItem.ItemType,
        itemId: UUID,
        action: PendingSyncItem.Action,
        payload: Encodable
    ) {
        Task { @MainActor in
            self.performQueue(itemType: itemType, itemId: itemId, action: action, payload: payload)
        }
    }
    
    private func performQueue(
        itemType: PendingSyncItem.ItemType,
        itemId: UUID,
        action: PendingSyncItem.Action,
        payload: Encodable
    ) {
        guard let modelContext = modelContext else { return }
        
        do {
            let payloadData = try JSONEncoder().encode(payload)
            
            let syncItem = PendingSyncItem(
                itemType: itemType,
                itemId: itemId,
                action: action,
                payload: payloadData
            )
            
            modelContext.insert(syncItem)
            try modelContext.save()
            updateCounts()
            scheduleSyncIfNeeded()
        } catch {
            print("Failed to queue item for sync: \(error)")
        }
    }
    
    // MARK: - Sync Scheduling
    
    /// Schedules a debounced sync. Multiple rapid calls coalesce into one sync pass.
    private func scheduleSyncIfNeeded() {
        guard isConnected, !isSyncing, pendingCount > 0 else { return }
        guard APIService.shared.isAuthenticated else { return }
        
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .seconds(debounceInterval))
            guard !Task.isCancelled else { return }
            await syncPendingItems()
        }
    }
    
    // MARK: - Sync Execution
    
    func syncPendingItems() async {
        guard isConnected, !isSyncing else { return }
        guard APIService.shared.isAuthenticated else { return }
        guard let modelContext = modelContext else { return }
        
        isSyncing = true
        
        let maxRetries = maxRetryCount
        let descriptor = FetchDescriptor<PendingSyncItem>(
            predicate: #Predicate<PendingSyncItem> { item in
                item.retryCount < maxRetries
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        do {
            let pendingItems = try modelContext.fetch(descriptor)
            
            for item in pendingItems {
                guard isConnected else { break }
                
                do {
                    try await syncItem(item)
                    modelContext.delete(item)
                    try modelContext.save()
                } catch {
                    item.retryCount += 1
                    item.lastError = error.localizedDescription
                    try? modelContext.save()
                    
                    let backoff = min(pow(2.0, Double(item.retryCount)), 60)
                    try? await Task.sleep(for: .seconds(backoff))
                }
                
                // Rate limit: small delay between items
                try? await Task.sleep(for: .seconds(itemDelay))
            }
            
            lastSyncDate = Date()
        } catch {
            print("Failed to fetch pending items: \(error)")
        }
        
        isSyncing = false
        updateCounts()
        
        // Re-schedule if new items were queued during this sync pass
        if pendingCount > 0 {
            scheduleSyncIfNeeded()
        }
    }
    
    // MARK: - Individual Item Sync
    
    private func syncItem(_ item: PendingSyncItem) async throws {
        guard let itemType = PendingSyncItem.ItemType(rawValue: item.itemType),
              let action = PendingSyncItem.Action(rawValue: item.action) else {
            throw SyncError.invalidItem
        }
        
        let decoder = JSONDecoder()
        
        switch (itemType, action) {
        case (.personalExpense, .create):
            let request = try decoder.decode(CreatePersonalExpenseRequest.self, from: item.payload)
            _ = try await APIService.shared.createPersonalExpense(request)
            
        case (.personalExpense, .delete):
            _ = try await APIService.shared.deletePersonalExpense(id: item.itemId)
            
        case (.sharedExpense, .create):
            let request = try decoder.decode(CreateSharedExpenseRequest.self, from: item.payload)
            _ = try await APIService.shared.createExpense(request)
            
        case (.budget, .create), (.budget, .update):
            let request = try decoder.decode(SetBudgetRequest.self, from: item.payload)
            _ = try await APIService.shared.setBudget(
                amount: Double(request.amount) ?? 0,
                month: request.month,
                year: request.year
            )
            
        case (.category, .create), (.category, .update):
            let request = try decoder.decode(CreateCategoryRequest.self, from: item.payload)
            _ = try await APIService.shared.createCategory(
                name: request.name,
                color: request.color,
                icon: request.icon
            )
            
        default:
            throw SyncError.unsupportedOperation
        }
    }
    
    // MARK: - Counts
    
    private func updateCounts() {
        guard let modelContext = modelContext else { return }
        
        let maxRetries = maxRetryCount
        let retryableDescriptor = FetchDescriptor<PendingSyncItem>(
            predicate: #Predicate<PendingSyncItem> { item in
                item.retryCount < maxRetries
            }
        )
        let allDescriptor = FetchDescriptor<PendingSyncItem>()
        
        let retryableCount = (try? modelContext.fetchCount(retryableDescriptor)) ?? 0
        let totalCount = (try? modelContext.fetchCount(allDescriptor)) ?? 0
        
        pendingCount = retryableCount
        failedCount = totalCount - retryableCount
    }
    
    /// Clears items that have permanently failed (exceeded max retries).
    func clearFailedItems() {
        guard let modelContext = modelContext else { return }
        
        let maxRetries = maxRetryCount
        let failedDescriptor = FetchDescriptor<PendingSyncItem>(
            predicate: #Predicate<PendingSyncItem> { item in
                item.retryCount >= maxRetries
            }
        )
        
        guard let failedItems = try? modelContext.fetch(failedDescriptor) else { return }
        for item in failedItems {
            modelContext.delete(item)
        }
        try? modelContext.save()
        updateCounts()
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
