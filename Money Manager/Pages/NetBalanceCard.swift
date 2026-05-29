//
//  NetBalanceCard.swift
//  Money Manager
//

import SwiftUI

struct NetBalanceCard: View {
    let netBalance: Double
    let groupCount: Int

    private var isOwed: Bool { netBalance > 0 }
    private var isSettled: Bool { netBalance == 0 }

    var body: some View {
        VStack(spacing: AppConstants.UI.spacing12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Net Balance")
                        .font(AppTypography.subhead)
                        .foregroundStyle(AppColors.label2)
                    Text(CurrencyFormatter.format(abs(netBalance), showDecimals: true))
                        .font(AppTypography.amountHero)
                        .foregroundStyle(isSettled ? AppColors.label : (isOwed ? AppColors.positive : AppColors.expense))
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(isSettled ? AppColors.surface2 : (isOwed ? AppColors.positive.opacity(0.15) : AppColors.expense.opacity(0.15)))
                        .frame(width: 48, height: 48)
                    AppIcon(
                        name: isSettled ? AppIcons.UI.check : (isOwed ? AppIcons.UI.export : AppIcons.UI.back),
                        size: 22,
                        color: isSettled ? AppColors.label2 : (isOwed ? AppColors.positive : AppColors.expense)
                    )
                }
            }
            HStack {
                Text(isSettled ? "All settled up" : (isOwed ? "You are owed overall" : "You owe overall"))
                    .font(AppTypography.subhead)
                    .foregroundStyle(AppColors.label2)
                Spacer()
                Text("\(groupCount) group\(groupCount == 1 ? "" : "s")")
                    .font(AppTypography.subhead)
                    .foregroundStyle(AppColors.label2)
            }
        }
        .padding(AppConstants.UI.padding)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }
}
