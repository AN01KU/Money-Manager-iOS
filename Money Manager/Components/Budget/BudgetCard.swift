//
//  BudgetCard.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct BudgetCard: View {
    let budget: MonthlyBudget
    let spent: Double
    let remaining: Double
    let percentage: Int
    let daysRemaining: Int
    let dailyAverage: Double
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Budget")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(CurrencyFormatter.format(budget.limit))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.teal)
                }
            }
            
            Divider()
            
            // Spending Overview
            VStack(spacing: 12) {
                HStack {
                    Text("Spent")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.format(spent))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("Remaining")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.format(remaining))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(remaining > 0 ? .green : .red)
                }
            }
            
            // Progress Bar
            BudgetProgressBar(percentage: percentage)
            
            // Percentage
            HStack {
                Spacer()
                Text("\(percentage)% used")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Daily Average (if within current month)
            if daysRemaining > 0 && dailyAverage > 0 {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Average")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(CurrencyFormatter.format(dailyAverage))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Days Remaining")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(daysRemaining)")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct BudgetProgressBar: View {
    let percentage: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: progressColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(min(percentage, 100)) / 100.0, height: 16)
            }
        }
        .frame(height: 16)
    }
    
    private var progressColors: [Color] {
        if percentage <= 50 {
            return [Color.green, Color.green.opacity(0.7)]
        } else if percentage <= 80 {
            return [Color.orange, Color.orange.opacity(0.7)]
        } else {
            return [Color.red, Color.red.opacity(0.7)]
        }
    }
}

#Preview {
    BudgetCard(
        budget: MonthlyBudget(year: 2025, month: 1, limit: 50000),
        spent: 32450,
        remaining: 17550,
        percentage: 65,
        daysRemaining: 6,
        dailyAverage: 2925,
        onEdit: {}
    )
    .padding()
}
