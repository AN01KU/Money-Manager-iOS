import SwiftUI

struct RecurringSection: View {
    @Bindable var viewModel: TransactionEditorViewModel

    var body: some View {
        TxnCard {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: AppConstants.UI.spacingSM) {
                        AppIcon(name: AppIcons.UI.recurring, size: 20, color: AppColors.accent)
                        Text("Recurring")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.accent)
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.isRecurring)
                        .labelsHidden()
                        .tint(AppColors.accent)
                        .disabled(viewModel.editingRecurringExpenseId != nil)
                }

                if viewModel.isRecurring {
                    Divider().padding(.vertical, AppConstants.UI.spacing12)

                    if viewModel.editingRecurringExpenseId != nil {
                        Text("This transaction is linked to a recurring schedule. Edit the schedule from Settings → Recurring.")
                            .font(AppTypography.caption1)
                            .foregroundStyle(AppColors.label2)
                    } else {
                        TxnPickerRow(label: "Frequency") {
                            Picker("", selection: $viewModel.recurringFrequency) {
                                ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                                    Text(freq.rawValue.capitalized).tag(freq)
                                }
                            }
                            .tint(AppColors.accent)
                        }

                        if viewModel.recurringFrequency == .monthly {
                            Divider().padding(.vertical, AppConstants.UI.spacing12)
                            TxnPickerRow(label: "Day of Month") {
                                Picker("", selection: $viewModel.recurringDayOfMonth) {
                                    ForEach(1...28, id: \.self) { day in
                                        Text("\(day)").tag(day)
                                    }
                                }
                                .tint(AppColors.accent)
                            }
                        }

                        Divider().padding(.vertical, AppConstants.UI.spacing12)

                        HStack {
                            Text("Set End Date")
                                .font(AppTypography.body)
                            Spacer()
                            Toggle("", isOn: $viewModel.recurringHasEndDate)
                                .labelsHidden()
                                .tint(AppColors.accent)
                        }

                        if viewModel.recurringHasEndDate {
                            Divider().padding(.vertical, AppConstants.UI.spacing12)
                            DatePicker("End Date", selection: $viewModel.recurringEndDate,
                                       in: viewModel.selectedDate..., displayedComponents: .date)
                                .font(AppTypography.body)
                        }
                    }
                }
            }
        }
    }
}
