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
        HStack(spacing: AppConstants.UI.spacing12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.accentLight)
                    .frame(width: AppConstants.UI.iconBadgeSize, height: AppConstants.UI.iconBadgeSize)
                Text(String(group.name.prefix(1)).uppercased())
                    .font(AppTypography.body)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.label)
                HStack(spacing: 4) {
                    AppIcon(name: AppIcons.UI.groups, size: 12, color: AppColors.label2)
                    Text("\(memberCount) member\(memberCount == 1 ? "" : "s")")
                        .font(AppTypography.caption1)
                        .foregroundStyle(AppColors.label2)
                }
            }

            Spacer()

            if userBalance != 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(CurrencyFormatter.format(abs(userBalance), showDecimals: true))
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(userBalance > 0 ? AppColors.positive : AppColors.expense)
                    Text(userBalance > 0 ? "owed" : "you owe")
                        .font(AppTypography.caption1)
                        .foregroundStyle(AppColors.label2)
                }
            } else {
                Text("settled")
                    .font(AppTypography.caption1)
                    .foregroundStyle(AppColors.label2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.surface2)
                    .clipShape(Capsule())
            }

            AppIcon(name: AppIcons.UI.chevron, size: 12, color: AppColors.label3)
        }
        .padding(.vertical, AppConstants.UI.spacing12)
        .padding(.horizontal, AppConstants.UI.padding)
    }
}
