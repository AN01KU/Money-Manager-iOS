import SwiftUI

struct SplitSection: View {
    @Bindable var viewModel: AddTransactionViewModel

    var body: some View {
        Section("Split") {
            Picker("Split Type", selection: $viewModel.splitType) {
                ForEach(SplitType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            if viewModel.splitType == .equal && !viewModel.selectedMembers.isEmpty {
                HStack {
                    Text("Each person pays").foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.equalShareText).fontWeight(.semibold).foregroundStyle(.primary)
                }
                .font(.subheadline)
            }
        }

        if viewModel.splitType == .custom && !viewModel.selectedMembers.isEmpty {
            Section {
                HStack {
                    Text("Total assigned")
                    Spacer()
                    Text(CurrencyFormatter.format(viewModel.customSplitTotal, showDecimals: true))
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.splitMatchesTotal ? AppColors.income : AppColors.expense)
                }
                if !viewModel.splitMatchesTotal {
                    let diff = (Double(viewModel.amount) ?? 0) - viewModel.customSplitTotal
                    HStack {
                        Text(diff > 0 ? "Remaining" : "Over by").foregroundStyle(.secondary)
                        Spacer()
                        Text(CurrencyFormatter.format(abs(diff), showDecimals: true)).foregroundStyle(AppColors.warning)
                    }
                    .font(.caption)
                }
            } footer: {
                if !viewModel.splitMatchesTotal {
                    Text("Custom split amounts must equal the total.").foregroundStyle(AppColors.expense)
                }
            }
        }
    }
}
