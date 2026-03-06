import SwiftUI

struct ExportDataView: View {
    var body: some View {
        EmptyStateView(
            icon: "square.and.arrow.up",
            title: "Export Coming Soon",
            message: "Export your expenses and budgets as CSV or PDF"
        )
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ExportDataView()
}
