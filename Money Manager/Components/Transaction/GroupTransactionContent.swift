import SwiftUI

// MARK: - Settlement Transaction Content

struct SettlementTransactionContent: View {
    let groupName: String?
    let groupId: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            guard authService.isAuthenticated else { return }
            if let groupId {
                dismiss()
                let route = AppRoute.group(groupId)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    NotificationCenter.default.post(name: .appRouteReceived, object: route)
                }
            }
        } label: {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .font(AppTypography.infoValue)
                    .foregroundStyle(AppColors.warning)

                VStack(alignment: .leading, spacing: 4) {
                    Text(groupName ?? "Unknown Group")
                        .font(AppTypography.infoValue)
                        .foregroundStyle(.primary)

                    Text(authService.isAuthenticated ? "Settlement — Tap to view group" : "Settlement — Sign in to view group")
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: authService.isAuthenticated ? "chevron.right" : "lock.fill")
                    .font(AppTypography.cardLabel)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(AppColors.warning.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Group Transaction Content

struct GroupTransactionContent: View {
    let groupName: String?
    let groupId: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            guard authService.isAuthenticated else { return }
            if let groupId {
                dismiss()
                let route = AppRoute.group(groupId)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    NotificationCenter.default.post(name: .appRouteReceived, object: route)
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(groupName ?? "Unknown Group")
                        .font(AppTypography.infoValue)
                        .foregroundStyle(.primary)

                    Text(authService.isAuthenticated ? "Tap to view group" : "Sign in to view group")
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: authService.isAuthenticated ? "chevron.right" : "lock.fill")
                    .font(AppTypography.cardLabel)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(AppColors.accentLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
