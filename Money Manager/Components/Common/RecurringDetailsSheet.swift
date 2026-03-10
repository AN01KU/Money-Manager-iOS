import SwiftUI

struct RecurringDetailsSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var frequency: String
    @Binding var dayOfMonth: Int
    @Binding var hasEndDate: Bool
    @Binding var recurringEndDate: Date
    
    let frequencies = ["daily", "weekly", "monthly", "yearly"]
    let startDate: Date
    
    init(
        frequency: Binding<String>,
        dayOfMonth: Binding<Int>,
        hasEndDate: Binding<Bool>,
        recurringEndDate: Binding<Date>,
        startDate: Date = Date()
    ) {
        self._frequency = frequency
        self._dayOfMonth = dayOfMonth
        self._hasEndDate = hasEndDate
        self._recurringEndDate = recurringEndDate
        self.startDate = startDate
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Frequency")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Frequency", selection: $frequency) {
                            ForEach(frequencies, id: \.self) { freq in
                                Text(freq.capitalized).tag(freq)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 8)
                    
                    if frequency == "monthly" {
                        Picker("Day of Month", selection: $dayOfMonth) {
                            ForEach(1...28, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                    }
                    
                    DatePicker("Start Date", selection: .constant(startDate), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .disabled(true)
                }
                
                Section {
                    Toggle("Set End Date", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: $recurringEndDate, in: startDate..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }
            }
            .navigationTitle("Recurring Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    RecurringDetailsSheet(
        frequency: .constant("monthly"),
        dayOfMonth: .constant(1),
        hasEndDate: .constant(false),
        recurringEndDate: .constant(Date())
    )
}
