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

    private var status: BudgetStatus { BudgetStatus(spent: spent, limit: limit) }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status.icon)
                .font(.title2)
                .foregroundStyle(status.color)

            VStack(alignment: .leading, spacing: 4) {
                Text(status.title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(status.message(spent: spent, limit: limit))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(status.color.opacity(0.1))
        .foregroundStyle(status.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(status.title), \(status.message(spent: spent, limit: limit))")
    }
}

#Preview {
    VStack(spacing: 16) {
        BudgetStatusBanner(spent: 45000, limit: 50000)
        BudgetStatusBanner(spent: 30000, limit: 50000)
        BudgetStatusBanner(spent: 55000, limit: 50000)
    }
    .padding()
}
