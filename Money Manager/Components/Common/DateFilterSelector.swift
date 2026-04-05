//
//  DateFilterSelector.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 15/01/26.
//

import SwiftUI

enum FilterMode {
    case daily
    case monthly
}

struct DateFilterSelector: View {
    @Binding var selectedDate: Date
    @Binding var filterMode: FilterMode
    @State private var showDatePicker = false
    @State private var datePickerTapped = 0
    @State private var filterToggled = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Date Picker Button
            Button(action: {
                datePickerTapped += 1
                showDatePicker = true
            }) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(selectedDate, format: filterMode == .daily
                        ? .dateTime.day().month(.abbreviated).year()
                        : .dateTime.month(.wide).year())
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
            .sensoryFeedback(.impact(weight: .light), trigger: datePickerTapped)
            
            // Filter Mode Toggle
            Button(action: {
                filterToggled += 1
                filterMode = filterMode == .daily ? .monthly : .daily
            }) {
                HStack(spacing: 6) {
                    Image(systemName: filterMode == .daily ? "calendar.badge.clock" : "calendar")
                        .font(.caption)
                    Text(filterMode == .daily ? "Daily" : "Monthly")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(AppColors.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .sensoryFeedback(.selection, trigger: filterToggled)
            
            Spacer()
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                }
                .navigationTitle("Select Date")
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
    DateFilterSelector(
        selectedDate: .constant(Date()),
        filterMode: .constant(.daily)
    )
    .padding()
}
