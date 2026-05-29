import SwiftUI

struct TxnCard<Content: View>: View {
    var padding: CGFloat = AppConstants.UI.padding
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }
}

struct TxnPickerRow<Picker: View>: View {
    let label: String
    @ViewBuilder let picker: Picker

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
            Spacer()
            picker
        }
    }
}
