#if DEBUG
import SwiftUI
import SwiftData

struct SyncDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PendingChange.createdAt) private var pendingChanges: [PendingChange]
    @Query(sort: \FailedChange.failedAt, order: .reverse) private var failedChanges: [FailedChange]

    @State private var isSyncing = false

    var body: some View {
        List {
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
                    isSyncing = true
                    Task {
                        await changeQueueManager.replayAll(context: modelContext)
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
                            Text(change.lastError)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Failed \(change.failedAt.formatted(.relative(presentation: .named)))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

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

    private func retryFailed(_ failed: FailedChange) {
        changeQueueManager.enqueue(
            entityType: failed.entityType,
            entityID: failed.entityID,
            action: failed.action,
            endpoint: failed.endpoint,
            httpMethod: failed.httpMethod,
            payload: failed.payload,
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
    .modelContainer(for: [PendingChange.self, FailedChange.self])
}
#endif
