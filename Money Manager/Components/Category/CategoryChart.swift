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
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 20) {
                Chart(pieData) { spending in
                    SectorMark(
                        angle: .value("Amount", spending.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(spending.color)
                    .opacity(0.8)
                }
                .frame(width: 140, height: 140)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(pieData) { spending in
                        CategorySpendingRow(spending: spending)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            if !categorySpending.isEmpty {
                VStack(spacing: 0) {
                    ForEach(categorySpending) { spending in
                        CategoryDetailRow(spending: spending, maxAmount: categorySpending.first?.amount ?? 1)
                        
                        if spending.id != categorySpending.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(spending.percentage)%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(spending.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: spending.icon)
                    .font(.body)
                    .foregroundColor(spending.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(spending.categoryName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(CurrencyFormatter.format(spending.amount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray4))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(spending.color)
                            .frame(width: geometry.size.width * barFraction, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
