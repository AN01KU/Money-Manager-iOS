//
//  GroupMemberRow.swift
//  Money Manager
//

import SwiftUI

struct GroupMemberRow: View {
    let member: APIGroupMember
    let isAdmin: Bool
    var isPending: Bool = false
    var balance: Double? = nil

    private var displayName: String {
        member.username
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isPending ? AppColors.warning.opacity(0.15) : AppColors.accentSubtle)
                    .frame(width: 36, height: 36)
                if isPending {
                    Image(systemName: "clock")
                        .font(AppTypography.rowPrimary)
                        .foregroundStyle(AppColors.warning)
                } else {
                    Text(String(member.email.prefix(1)).uppercased())
                        .font(AppTypography.rowPrimary)
                        .foregroundStyle(AppColors.accent)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(AppTypography.rowPrimary)
                    .foregroundStyle(isPending ? .secondary : .primary)
                Text(member.email)
                    .font(AppTypography.rowMeta)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                if let bal = balance, abs(bal) > 0.01 {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(CurrencyFormatter.format(abs(bal), showDecimals: true))
                            .font(AppTypography.rowMeta)
                            .fontWeight(.semibold)
                            .foregroundStyle(bal > 0 ? AppColors.positive : AppColors.expense)
                        Text(bal > 0 ? "is owed" : "owes")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                if isPending {
                    Text("Invited")
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(AppColors.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.warning.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 6))
                } else if isAdmin {
                    Text("Admin")
                        .font(AppTypography.rowMeta)
                        .foregroundStyle(AppColors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.accentSubtle)
                        .clipShape(.rect(cornerRadius: 6))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
