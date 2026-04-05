import SwiftUI

struct QuickAmountButton: View {
    let amount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(CurrencyFormatter.currentSymbol)\(amount)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppColors.accentLight)
                .foregroundStyle(AppColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.borderless)
        .accessibilityIdentifier("quick-amount-\(amount)")
    }
}
