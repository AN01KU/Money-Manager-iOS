import SwiftUI

struct QuickAmountButton: View {
    let amount: Int
    let action: () -> Void

    private var label: String {
        amount > 0 ? "+\(amount)" : "\(amount)"
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppTypography.subhead)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(AppColors.accentLight)
                .foregroundStyle(AppColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.radius10))
        }
        .buttonStyle(.borderless)
        .accessibilityIdentifier("quick-amount-\(amount)")
    }
}
