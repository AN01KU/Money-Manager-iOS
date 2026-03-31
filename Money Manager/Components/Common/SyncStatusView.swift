import SwiftUI

/// Displays the current sync state as a compact inline pill.
/// States (in priority order): syncing → offline → error → pending → synced
struct SyncStatusView: View {
    @Environment(\.syncService) private var syncService
    @Environment(\.changeQueueManager) private var changeQueueManager

    private var status: SyncStatus {
        if syncService.isSyncing {
            return .syncing
        }
        if !NetworkMonitor.shared.isConnected {
            return .offline
        }
        if changeQueueManager.failedCount > 0 {
            return .error(changeQueueManager.failedCount)
        }
        if changeQueueManager.pendingCount > 0 {
            return .pending(changeQueueManager.pendingCount)
        }
        if let date = syncService.lastSyncedAt {
            return .synced(date)
        }
        return .idle
    }

    var body: some View {
        Label(status.label, systemImage: status.icon)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.12), in: Capsule())
            .contentTransition(.identity)
            .animation(.easeInOut(duration: 0.2), value: status.label)
    }
}

// MARK: - State

private enum SyncStatus: Equatable {
    case syncing
    case offline
    case error(Int)
    case pending(Int)
    case synced(Date)
    case idle

    var label: String {
        switch self {
        case .syncing:          return "Syncing…"
        case .offline:          return "Offline"
        case .error(let n):     return n == 1 ? "1 sync error" : "\(n) sync errors"
        case .pending(let n):   return n == 1 ? "1 change pending" : "\(n) changes pending"
        case .synced(let date): return "Synced \(date.formatted(.relative(presentation: .named)))"
        case .idle:             return "Not synced"
        }
    }

    var icon: String {
        switch self {
        case .syncing:  return "arrow.triangle.2.circlepath"
        case .offline:  return "wifi.slash"
        case .error:    return "exclamationmark.icloud"
        case .pending:  return "icloud.and.arrow.up"
        case .synced:   return "checkmark.icloud"
        case .idle:     return "icloud.slash"
        }
    }

    var color: Color {
        switch self {
        case .syncing:  return .blue
        case .offline:  return .secondary
        case .error:    return .red
        case .pending:  return .orange
        case .synced:   return .green
        case .idle:     return .secondary
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SyncStatusView()
    }
    .padding()
}
