#if DEBUG
import SwiftUI
import SwiftData

struct SyncDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.authService) private var authService
    @Environment(\.syncService) private var syncService
    @Environment(\.changeQueueManager) private var changeQueueManager
    @Environment(\.networkMonitor) private var networkMonitor
    @Query(filter: #Predicate<ChangeRecord> { $0.statusRaw == "pending" }, sort: \ChangeRecord.createdAt)
    private var pendingChanges: [ChangeRecord]
    @Query(filter: #Predicate<ChangeRecord> { $0.statusRaw == "failed" }, sort: \ChangeRecord.createdAt, order: .reverse)
    private var failedChanges: [ChangeRecord]

    @State private var isSyncing = false
    @State private var isFullSyncing = false

    private var totalSyncs: Int { syncService.syncSuccessCount + syncService.syncFailureCount }
    private var successRate: String {
        guard totalSyncs > 0 else { return "—" }
        let pct = Int((Double(syncService.syncSuccessCount) / Double(totalSyncs)) * 100)
        return "\(pct)%"
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Last Sync")
                    Spacer()
                    if let date = syncService.lastSyncedAt {
                        Text(date.formatted(.relative(presentation: .named)))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Never")
                            .foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Text("Success / Failure")
                    Spacer()
                    Text("\(syncService.syncSuccessCount) / \(syncService.syncFailureCount)")
                        .foregroundStyle(syncService.syncFailureCount > 0 ? Color.red : Color.secondary)
                }
                HStack {
                    Text("Success Rate (this session)")
                    Spacer()
                    Text(successRate)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Sync Stats")
            }

            Section {
                HStack {
                    Text("Pending")
                    Spacer()
                    Text("\(pendingChanges.count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Failed (Dead Letter)")
                    Spacer()
                    Text("\(failedChanges.count)")
                        .foregroundStyle(failedChanges.isEmpty ? Color.secondary : Color.red)
                }
            } header: {
                Text("Queue Status")
            }

            Section {
                Button {
                    isFullSyncing = true
                    Task {
                        await syncService.fullSync()
                        isFullSyncing = false
                    }
                } label: {
                    HStack {
                        Label("Full Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        if isFullSyncing { Spacer(); ProgressView() }
                    }
                }
                .disabled(isFullSyncing || !networkMonitor.isConnected)

                Button {
                    isSyncing = true
                    Task {
                        await changeQueueManager.replayAll(context: modelContext, isAuthenticated: authService.isAuthenticated)
                        isSyncing = false
                    }
                } label: {
                    HStack {
                        Label("Retry Pending Now", systemImage: "arrow.clockwise")
                        if isSyncing { Spacer(); ProgressView() }
                    }
                }
                .disabled(pendingChanges.isEmpty || isSyncing)
            } header: {
                Text("Actions")
            }

            if !pendingChanges.isEmpty {
                Section {
                    ForEach(pendingChanges) { change in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(change.httpMethod) \(change.entityType)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("retry \(change.retryCount)/\(ChangeQueueManager.maxRetryCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(change.endpoint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let next = change.nextRetryAt, next > Date() {
                                Text("Next retry: \(next.formatted(.relative(presentation: .named)))")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Pending Changes")
                }
            }

            if !failedChanges.isEmpty {
                Section {
                    ForEach(failedChanges) { change in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(change.httpMethod) \(change.entityType)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("failed after \(change.retryCount) retries")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            if let error = change.lastError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let failedAt = change.failedAt {
                                Text("Failed \(failedAt.formatted(.relative(presentation: .named)))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Button("Retry") {
                                retryFailed(change)
                            }
                            .font(.caption)
                            .foregroundStyle(AppColors.accent)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Dead Letter Queue")
                } footer: {
                    Text("These items exceeded \(ChangeQueueManager.maxRetryCount) retries. Tap Retry to re-queue them.")
                }
            }
        }
        .navigationTitle("Sync Debug")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func retryFailed(_ failed: ChangeRecord) {
        guard
            let entityType = EntityType(rawValue: failed.entityType),
            let action = ChangeAction(rawValue: failed.action),
            let httpMethod = HTTPMethod(rawValue: failed.httpMethod)
        else { return }
        changeQueueManager.enqueue(
            PendingChangeDraft(
                entityType: entityType,
                entityID: failed.entityID,
                action: action,
                endpoint: failed.endpoint,
                httpMethod: httpMethod,
                payload: failed.payload
            ),
            context: modelContext
        )
        modelContext.delete(failed)
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        SyncDebugView()
    }
    .modelContainer(for: [ChangeRecord.self])
}
#endif
