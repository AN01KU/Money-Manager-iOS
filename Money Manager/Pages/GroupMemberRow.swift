//
//  GroupMemberRow.swift
//  Money Manager
//

import SwiftUI

struct GroupMemberRow: View {
    let member: APIGroupMember
    let isAdmin: Bool
    var isPending: Bool = false

    private var displayName: String {
        member.email.components(separatedBy: "@").first?.capitalized ?? member.email
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isPending ? AppColors.warning.opacity(0.12) : AppColors.accentSubtle)
                    .frame(width: 40, height: 40)
                if isPending {
                    Image(systemName: "clock")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.warning)
                } else {
                    Text(String(member.email.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundStyle(AppColors.accent)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(isPending ? .secondary : .primary)
                Text(member.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isPending {
                Text("Invited")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.warning.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 6))
            } else if isAdmin {
                Text("Admin")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.accentSubtle)
                    .clipShape(.rect(cornerRadius: 6))
            }
        }
        .padding(.vertical, 2)
    }
}
