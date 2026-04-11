import SwiftUI

struct CategoryRow: View {
    let category: TransactionCategory
    var usageCount: Int = 0
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .foregroundStyle(category.color)
                    .frame(width: 28)

                Text(category.name)
                    .font(.body)

                Spacer()

                if usageCount > 0 {
                    Text("\(usageCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                if category.isPredefined {
                    Text("Default")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.name), \(usageCount) transactions, \(category.isPredefined ? "Default category" : "Custom category")")
    }
}
