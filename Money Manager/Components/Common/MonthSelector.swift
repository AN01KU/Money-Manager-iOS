//
//  MonthSelector.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct MonthSelector: View {
    @Binding var selectedMonth: Date
    @State private var showDatePicker = false
    @State private var buttonTapped = false
    
    var body: some View {
        Button(action: {
            buttonTapped = true
            showDatePicker = true
        }) {
            HStack {
                Text(formatMonth(selectedMonth))
                    .font(.body)
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .sensoryFeedback(.impact(weight: .light), trigger: buttonTapped)
        .onChange(of: buttonTapped) { _, newValue in
            if newValue { buttonTapped = false }
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "Select Month",
                        selection: $selectedMonth,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                }
                .navigationTitle("Select Month")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
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
