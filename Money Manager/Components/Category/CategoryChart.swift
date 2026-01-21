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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 20) {
                Chart(categorySpending) { spending in
                    SectorMark(
                        angle: .value("Amount", spending.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(spending.category.color)
                    .opacity(0.8)
                }
                .frame(width: 140, height: 140)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(categorySpending.prefix(5)) { spending in
                        CategorySpendingRow(spending: spending)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
}

struct CategorySpendingRow: View {
    let spending: CategorySpending
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(spending.category.color)
                .frame(width: 14, height: 14)
            
            Text(spending.category.rawValue)
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

#Preview {
    CategoryChart(categorySpending: [
        CategorySpending(category: .food, amount: 11308, percentage: 35),
        CategorySpending(category: .transport, amount: 6490, percentage: 20),
        CategorySpending(category: .other, amount: 14652, percentage: 45)
    ])
    .padding()
}
