import SwiftUI
import SwiftData

private struct TransactionGroup: Identifiable {
    let id: String   // the display label, e.g. "TODAY" or "JANUARY 15"
    let transactions: [Transaction]
}

private let sectionDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMMM dd"
    return f
}()

struct TransactionList: View {
    let transactions: [Transaction]
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    @State private var selectedTransaction: Transaction?
    @State private var editingTransaction: Transaction?
    @State private var swipedTransactionID: PersistentIdentifier?
    @State private var rowTapped = 0
    @State private var deleteTriggered = false  // Used as binding for swipe UI
    var onDelete: ((Transaction) -> Void)?
    var onGroupTapped: ((UUID) -> Void)?

    private var categoryLookup: [String: CustomCategory] {
        CategoryResolver.makeLookup(from: customCategories)
    }

    private var groupedTransactions: [TransactionGroup] {
        let calendar = Calendar.current
        var grouped: [String: [Transaction]] = [:]

        for transaction in transactions {
            let transactionDate = calendar.startOfDay(for: transaction.date)
            let key = calendar.isDateInToday(transactionDate)
                ? "TODAY"
                : sectionDateFormatter.string(from: transactionDate).uppercased()

            grouped[key, default: []].append(transaction)
        }

        return grouped
            .map { TransactionGroup(id: $0.key, transactions: $0.value) }
            .sorted { first, second in
                if first.id == "TODAY" { return true }
                if second.id == "TODAY" { return false }
                return first.id > second.id
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(groupedTransactions) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.id)
                        .font(AppTypography.sectionHeader)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    VStack(spacing: 0) {
                        ForEach(section.transactions) { transaction in
                            SwipeToDeleteRow(
                                isRevealed: Binding(
                                    get: { swipedTransactionID == transaction.persistentModelID },
                                    set: { revealed in
                                        swipedTransactionID = revealed ? transaction.persistentModelID : nil
                                    }
                                ),
                                onDelete: {
                                    deleteTriggered = true
                                    onDelete?(transaction)
                                },
                                onTap: {
                                    rowTapped += 1
                                    selectedTransaction = transaction
                                }
                            ) {
                                TransactionRow(transaction: transaction, categoryLookup: categoryLookup, onGroupTapped: onGroupTapped)
                            }

                            if transaction.persistentModelID != section.transactions.last?.persistentModelID {
                                Divider()
                                    .padding(.leading, AppConstants.UI.iconBadgeSize + AppConstants.UI.spacing12 + AppConstants.UI.padding)
                            }
                        }
                    }
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(transaction: transaction, onEdit: { txn in
                selectedTransaction = nil
                editingTransaction = txn
            })
        }
        .sheet(item: $editingTransaction) { txn in
            AddTransactionView(transactionToEdit: txn)
        }
        .onChange(of: transactions.map(\.persistentModelID)) { _, _ in
            swipedTransactionID = nil
        }
    }
}


#Preview {
    TransactionList(transactions: [
        Transaction(amount: 450, category: "Food & Dining", date: Date(), transactionDescription: "Lunch"),
        Transaction(amount: 250, category: "Transport", date: Date(), transactionDescription: "Uber")
    ]) { _ in }
    .padding()
}
