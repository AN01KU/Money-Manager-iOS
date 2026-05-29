import SwiftUI

struct DateRow: View {
    @Bindable var viewModel: TransactionEditorViewModel

    var body: some View {
        TxnCard {
            VStack(alignment: .leading, spacing: AppConstants.UI.spacing12) {
                HStack {
                    Text(viewModel.isRecurring ? "Start Date *" : "Date *")
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                    Spacer()
                    DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }

                HStack(spacing: AppConstants.UI.spacingSM) {
                    QuickDateButton(label: "Today") { viewModel.selectedDate = Date() }
                        .tapFeedback()
                    QuickDateButton(label: "Yesterday") {
                        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                    }
                    .tapFeedback()
                }

                if !viewModel.isRecurring {
                    Divider()
                    Toggle(isOn: $viewModel.hasTime) {
                        Text("Include Time")
                            .font(AppTypography.body)
                    }
                    .tint(AppColors.accent)

                    if viewModel.hasTime {
                        DatePicker("", selection: $viewModel.selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                }
            }
        }
    }
}
