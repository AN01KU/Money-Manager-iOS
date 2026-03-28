import SwiftUI
import SwiftData

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.timeStyle = .short
    return f
}()

struct TransactionRow: View {
    let transaction: Transaction
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    init(transaction: Transaction) {
        self.transaction = transaction
    }

    private var resolved: (icon: String, color: Color) {
        CategoryResolver.resolve(transaction.category, customCategories: customCategories)
    }

    private var resolvedIcon: String { resolved.icon }
    private var resolvedColor: Color { resolved.color }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(resolvedColor.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: resolvedIcon)
                    .font(.title3)
                    .foregroundStyle(resolvedColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(transaction.transactionDescription ?? "No description")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if transaction.groupTransactionId != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("Group transaction")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(AppColors.accent)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.format(transaction.amount))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(transaction.type == "income" ? AppColors.positive : .red)

                if let time = transaction.time {
                    Text(formatTime(time))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.category), \(transaction.transactionDescription ?? "No description"), \(CurrencyFormatter.format(transaction.amount))")
    }

    private func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}

#Preview {
    TransactionRow(
        transaction: Transaction(
            amount: 450,
            category: "Food & Dining",
            date: Date(),
            time: Date(),
            transactionDescription: "Lunch at cafe"
        )
    )
    .padding()
    .modelContainer(for: [CustomCategory.self], inMemory: true)
}
