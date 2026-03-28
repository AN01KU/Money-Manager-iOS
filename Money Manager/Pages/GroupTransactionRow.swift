import SwiftUI

struct GroupTransactionRow: View {
    let transaction: APIGroupTransaction
    let members: [APIGroupMember]

    private var amount: Double { Double(transaction.total_amount) ?? 0 }

    private var paidByName: String {
        members.first(where: { $0.id == transaction.paid_by_user_id })?
            .email.components(separatedBy: "@").first?.capitalized ?? "Unknown"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description ?? transaction.category)
                    .font(.body)
                    .fontWeight(.medium)
                Text(transaction.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text("Paid by").foregroundStyle(.secondary)
                    Text(paidByName).foregroundStyle(AppColors.accent)
                }
                .font(.caption)
                Text(transaction.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(CurrencyFormatter.format(amount, showDecimals: true))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}
