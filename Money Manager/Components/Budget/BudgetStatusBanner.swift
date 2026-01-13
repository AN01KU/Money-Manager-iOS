//
//  BudgetStatusBanner.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct BudgetStatusBanner: View {
    let spent: Double
    let limit: Double
    let percentage: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(statusColor.opacity(0.1))
        .foregroundColor(statusColor)
        .cornerRadius(12)
    }
    
    private var statusIcon: String {
        if percentage > 100 {
            return "exclamationmark.triangle.fill"
        } else if percentage > 80 {
            return "exclamationmark.circle.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if percentage > 100 {
            return .red
        } else if percentage > 80 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var statusTitle: String {
        if percentage > 100 {
            return "Over Budget"
        } else if percentage > 80 {
            return "Approaching Limit"
        } else {
            return "Within Budget"
        }
    }
    
    private var statusMessage: String {
        if percentage > 100 {
            let over = CurrencyFormatter.format(spent - limit)
            return "You've exceeded by \(over)"
        } else if percentage > 80 {
            let remaining = CurrencyFormatter.format(limit - spent)
            return "\(remaining) remaining"
        } else {
            let remaining = CurrencyFormatter.format(limit - spent)
            return "\(remaining) remaining this month"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        BudgetStatusBanner(spent: 45000, limit: 50000, percentage: 90)
        BudgetStatusBanner(spent: 30000, limit: 50000, percentage: 60)
        BudgetStatusBanner(spent: 55000, limit: 50000, percentage: 110)
    }
    .padding()
}
