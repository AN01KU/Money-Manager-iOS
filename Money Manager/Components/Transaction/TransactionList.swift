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
    @State private var selectedTransaction: Transaction?
    @State private var swipedTransactionID: PersistentIdentifier?
    @State private var rowTapped = 0
    @State private var deleteTriggered = false  // Used as binding for swipe UI
    var onDelete: ((Transaction) -> Void)?
    var onGroupTapped: ((UUID) -> Void)?

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
                                onTap: {
                                    rowTapped += 1
                                    selectedTransaction = transaction
                                },
                                onDelete: {
                                    deleteTriggered = true
                                    onDelete?(transaction)
                                }
                            ) {
                                TransactionRow(transaction: transaction, onGroupTapped: onGroupTapped)
                            }

                            if transaction.persistentModelID != section.transactions.last?.persistentModelID {
                                Divider()
                                    .padding(.leading, 58)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(transaction: transaction)
        }
    }
}

// MARK: - Swipe to Delete

private struct SwipeToDeleteRow<Content: View>: View {
    @Binding var isRevealed: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0

    private let buttonWidth: CGFloat = 80

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button behind
            Button {
                onDelete()
                resetSwipe()
            } label: {
                Image(systemName: "trash.fill")
                    .font(AppTypography.destructiveIcon)
                    .foregroundStyle(.white)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
            }
            .background(AppColors.expense)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(offset < 0 ? 1 : 0)

            // Content on top
            content()
                .offset(x: offset)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            let translation = value.translation.width
                            if isRevealed {
                                // Already open — allow dragging from revealed position
                                let newOffset = -buttonWidth + translation
                                offset = min(0, newOffset)
                            } else if translation < 0 {
                                // Swiping left to reveal
                                offset = max(-buttonWidth, translation)
                            }
                        }
                        .onEnded { value in
                            let snapThreshold: CGFloat = -40
                            if offset < snapThreshold {
                                revealButton()
                            } else {
                                resetSwipe()
                            }
                        }
                )
                .simultaneousGesture(
                    TapGesture().onEnded {
                        if isRevealed {
                            resetSwipe()
                        } else {
                            onTap()
                        }
                    }
                )
        }
        .onChange(of: isRevealed) { _, newValue in
            if !newValue && offset != 0 {
                withAnimation(.easeOut(duration: 0.2)) { offset = 0 }
            }
        }
        .accessibilityAction(named: "Delete") {
            onDelete()
        }
    }

    private func revealButton() {
        withAnimation(.easeOut(duration: 0.2)) { offset = -buttonWidth }
        isRevealed = true
    }

    private func resetSwipe() {
        withAnimation(.easeOut(duration: 0.2)) { offset = 0 }
        isRevealed = false
    }
}

#Preview {
    TransactionList(transactions: [
        Transaction(amount: 450, category: "Food & Dining", date: Date(), transactionDescription: "Lunch"),
        Transaction(amount: 250, category: "Transport", date: Date(), transactionDescription: "Uber")
    ]) { _ in }
    .padding()
}
