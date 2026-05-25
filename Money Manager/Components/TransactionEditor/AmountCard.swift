import SwiftUI

struct AmountCard: View {
    @Bindable var viewModel: TransactionEditorViewModel

    var body: some View {
        TxnCard {
            VStack(alignment: .leading, spacing: AppConstants.UI.spacing12) {
                Text("Amount *")
                    .font(AppTypography.subhead)
                    .foregroundStyle(AppColors.label2)

                TextField("0.00", text: $viewModel.amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(viewModel.amountText.isEmpty ? AppColors.label3 : AppColors.label)
                    .accessibilityIdentifier("amount-field")

                HStack(spacing: AppConstants.UI.spacingSM) {
                    QuickAmountButton(amount: -10) { adjustAmount(by: -10) }
                        .tapFeedback()
                    QuickAmountButton(amount: -100) { adjustAmount(by: -100) }
                        .tapFeedback()
                    QuickAmountButton(amount: 10) { adjustAmount(by: 10) }
                        .tapFeedback()
                    QuickAmountButton(amount: 100) { adjustAmount(by: 100) }
                        .tapFeedback()
                }

                Divider()

                EditorCategoryRow(viewModel: viewModel)
            }
        }
    }

    private func adjustAmount(by delta: Int) {
        let current = Double(viewModel.amountText) ?? 0
        let result = max(0, current + Double(delta))
        viewModel.amountText = result.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(result))
            : String(result)
    }
}
