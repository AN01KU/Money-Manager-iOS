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
    @State private var buttonTapped = 0
    
    var body: some View {
        Button(action: {
            buttonTapped += 1
            showDatePicker = true
        }) {
            HStack {
                Text(selectedMonth, format: .dateTime.month(.wide).year())
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
    
}

#Preview {
    MonthSelector(selectedMonth: .constant(Date()))
        .padding()
}
