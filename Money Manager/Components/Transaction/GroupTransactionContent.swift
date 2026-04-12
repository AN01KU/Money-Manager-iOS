import SwiftUI

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Shared Group Banner

/// Used in TransactionDetailView for both group transactions and settlements.
/// `isSettlement` switches the icon and accent color; everything else is shared.
private struct GroupBannerContent: View {
    @Environment(\.authService) private var authService
    let groupName: String?
    let groupId: UUID?
    let isSettlement: Bool
    var onDismiss: (() -> Void)? = nil

    private var accentColor: Color { isSettlement ? AppColors.warning : AppColors.accent }
    private var backgroundColor: Color { isSettlement ? AppColors.warning.opacity(0.12) : AppColors.accentLight }
    private var subtitle: String {
        guard authService.isAuthenticated else {
            return isSettlement ? "Settlement — Sign in to view group" : "Sign in to view group"
        }
        return isSettlement ? "Settlement — Tap to view group" : "Tap to view group"
    }

    var body: some View {
        Button {
            guard authService.isAuthenticated, let groupId else { return }
            onDismiss?()
            let route = AppRoute.group(groupId)
            Task {
                try? await Task.sleep(for: .milliseconds(350))
                NotificationCenter.default.post(name: .appRouteReceived, object: route)
            }
        } label: {
            HStack {
                if isSettlement {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(AppTypography.infoValue)
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(groupName ?? "Unknown Group")
                        .font(AppTypography.infoValue)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: authService.isAuthenticated ? "chevron.right" : "lock.fill")
                    .font(AppTypography.cardLabel)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Settlement Transaction Content

struct SettlementTransactionContent: View {
    let groupName: String?
    let groupId: UUID?
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        GroupBannerContent(groupName: groupName, groupId: groupId, isSettlement: true, onDismiss: onDismiss)
    }
}

// MARK: - Group Transaction Content

struct GroupTransactionContent: View {
    let groupName: String?
    let groupId: UUID?
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        GroupBannerContent(groupName: groupName, groupId: groupId, isSettlement: false, onDismiss: onDismiss)
    }
}
