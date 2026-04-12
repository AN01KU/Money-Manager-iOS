//
//  GroupHeaderStats.swift
//  Money Manager
//

import SwiftUI

struct GroupHeaderStats: View {
    let total: Double
    let transactionCount: Int
    let memberCount: Int

    var body: some View {
        HStack(spacing: 0) {
            statCell(value: CurrencyFormatter.format(total, showDecimals: true), label: "Total")
            Divider().frame(height: 32)
            statCell(value: "\(transactionCount)", label: "Transactions")
            Divider().frame(height: 32)
            statCell(value: "\(memberCount)", label: "Members")
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
