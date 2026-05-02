//
//  CategoryChart.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI
import Charts

struct CategoryChart: View {
    let categorySpending: [CategorySpending]
    var onCategoryTapped: ((String) -> Void)?
    
    private var pieData: [CategorySpending] {
        let sorted = categorySpending.sorted { $0.amount > $1.amount }
        guard sorted.count > 5 else { return sorted }
        
        let top4 = Array(sorted.prefix(4))
        let rest = sorted.dropFirst(4)
        let othersAmount = rest.reduce(0) { $0 + $1.amount }
        let othersPercentage = rest.reduce(0) { $0 + $1.percentage }
        let others = CategorySpending(
            categoryName: "Other",
            icon: "ellipsis.circle.fill",
            color: Color(hex: "#95A5A6"),
            amount: othersAmount,
            percentage: othersPercentage
        )
        return top4 + [others]
    }
    
    var body: some View {
        VStack(spacing: AppConstants.UI.spacing20) {
            // Donut chart card
            HStack(alignment: .top, spacing: 20) {
                Chart(pieData) { spending in
                    SectorMark(
                        angle: .value("Amount", spending.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(spending.color)
                    .opacity(0.9)
                }
                .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(pieData) { spending in
                        CategorySpendingRow(spending: spending)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppConstants.UI.padding)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))

            // Category breakdown card
            if !categorySpending.isEmpty {
                VStack(spacing: 0) {
                    ForEach(categorySpending) { spending in
                        Button {
                            onCategoryTapped?(spending.categoryKey)
                        } label: {
                            CategoryDetailRow(spending: spending, maxAmount: categorySpending.first?.amount ?? 1)
                        }
                        .buttonStyle(.plain)

                        if spending.id != categorySpending.last?.id {
                            Divider().padding(.leading, 64)
                        }
                    }
                }
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
            }
        }
    }
}

struct CategorySpendingRow: View {
    let spending: CategorySpending
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(spending.color)
                .frame(width: 14, height: 14)
            
            Text(spending.categoryName)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(spending.percentage)%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }
}

struct CategoryDetailRow: View {
    let spending: CategorySpending
    let maxAmount: Double
    
    private var barFraction: Double {
        guard maxAmount > 0 else { return 0 }
        return spending.amount / maxAmount
    }
    
    var body: some View {
        HStack(spacing: AppConstants.UI.spacing12) {
            ZStack {
                Circle()
                    .fill(spending.color.opacity(0.15))
                    .frame(width: AppConstants.UI.iconBadgeSize, height: AppConstants.UI.iconBadgeSize)
                AppIcon(name: spending.icon, size: AppConstants.UI.iconBadgeSize * 0.52, color: spending.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(spending.categoryName)
                        .font(AppTypography.body)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.label)

                    Spacer()

                    Text(CurrencyFormatter.format(spending.amount))
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.label)

                    AppIcon(name: AppIcons.UI.chevron, size: 14, color: AppColors.label3)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.surface2)
                            .frame(height: 5)
                        Capsule()
                            .fill(spending.color)
                            .frame(width: geometry.size.width * barFraction, height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(.horizontal, AppConstants.UI.padding)
        .padding(.vertical, AppConstants.UI.spacing12)
    }
}

#Preview {
    ScrollView {
        CategoryChart(categorySpending: [
            CategorySpending(categoryName: "Food & Dining", icon: "fork.knife.circle.fill", color: Color(hex: "#FF6B6B"), amount: 11308, percentage: 35),
            CategorySpending(categoryName: "Transport", icon: "car.circle.fill", color: Color(hex: "#4ECDC4"), amount: 6490, percentage: 20),
            CategorySpending(categoryName: "Shopping", icon: "bag.circle.fill", color: Color(hex: "#FFEAA7"), amount: 4200, percentage: 13),
            CategorySpending(categoryName: "Entertainment", icon: "gamecontroller.circle.fill", color: Color(hex: "#BC6C25"), amount: 3500, percentage: 11),
            CategorySpending(categoryName: "Utilities", icon: "bolt.square.fill", color: Color(hex: "#DDA15E"), amount: 2800, percentage: 9),
            CategorySpending(categoryName: "Housing", icon: "house.circle.fill", color: Color(hex: "#45B7D1"), amount: 2100, percentage: 6),
            CategorySpending(categoryName: "Other", icon: "ellipsis.circle.fill", color: Color(hex: "#95A5A6"), amount: 1952, percentage: 6)
        ])
        .padding()
    }
}
