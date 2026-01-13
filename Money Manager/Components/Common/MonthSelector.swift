//
//  MonthSelector.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct MonthSelector: View {
    @Binding var selectedMonth: Date
    
    var body: some View {
        Button(action: {
            // Could show month picker here later
        }) {
            HStack {
                Text(formatMonth(selectedMonth))
                    .font(.body)
                    .foregroundColor(.primary)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    MonthSelector(selectedMonth: .constant(Date()))
        .padding()
}
