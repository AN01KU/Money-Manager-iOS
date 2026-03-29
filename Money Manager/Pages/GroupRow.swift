//
//  GroupRow.swift
//  Money Manager
//

import SwiftUI

struct GroupRow: View {
    let group: APIGroupWithDetails
    let memberCount: Int
    let userBalance: Double

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.accentSubtle)
                    .frame(width: 48, height: 48)
                Text(String(group.name.prefix(1)).uppercased())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Label("\(memberCount) member\(memberCount == 1 ? "" : "s")", systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if userBalance != 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(CurrencyFormatter.format(abs(userBalance), showDecimals: true))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(userBalance > 0 ? AppColors.positive : AppColors.expense)
                    Text(userBalance > 0 ? "owed" : "owe")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("settled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(.rect(cornerRadius: 8))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}
