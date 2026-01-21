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
    
    var body: some View {
        HStack(spacing: 12) {
            // Date Picker Button
            Button(action: {
                showDatePicker = true
            }) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(formatDate(selectedDate))
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
            
            // Filter Mode Toggle
            Button(action: {
                filterMode = filterMode == .daily ? .monthly : .daily
            }) {
                HStack(spacing: 6) {
                    Image(systemName: filterMode == .daily ? "calendar.badge.clock" : "calendar")
                        .font(.caption)
                    Text(filterMode == .daily ? "Daily" : "Monthly")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.teal)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
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
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if filterMode == .daily {
            formatter.dateFormat = "MMM d, yyyy"
        } else {
            formatter.dateFormat = "MMMM yyyy"
        }
        return formatter.string(from: date)
    }
}

#Preview {
    DateFilterSelector(
        selectedDate: .constant(Date()),
        filterMode: .constant(.daily)
    )
    .padding()
}
