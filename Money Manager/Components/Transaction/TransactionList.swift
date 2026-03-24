//
//  TransactionList.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI
import SwiftData

private struct ExpenseGroup: Identifiable {
    let id: String   // the display label, e.g. "TODAY" or "JANUARY 15"
    let expenses: [Expense]
}

private let sectionDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMMM dd"
    return f
}()

struct TransactionList: View {
    let expenses: [Expense]
    @State private var selectedExpense: Expense?
    @State private var swipedExpenseID: PersistentIdentifier?
    @State private var rowTapped = false
    @State private var deleteTriggered = false
    var onDelete: ((Expense) -> Void)?

    private var groupedExpenses: [ExpenseGroup] {
        let calendar = Calendar.current
        var grouped: [String: [Expense]] = [:]

        for expense in expenses {
            let expenseDate = calendar.startOfDay(for: expense.date)
            let key = calendar.isDateInToday(expenseDate)
                ? "TODAY"
                : sectionDateFormatter.string(from: expenseDate).uppercased()

            grouped[key, default: []].append(expense)
        }

        return grouped
            .map { ExpenseGroup(id: $0.key, expenses: $0.value) }
            .sorted { first, second in
                if first.id == "TODAY" { return true }
                if second.id == "TODAY" { return false }
                return first.id > second.id
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(groupedExpenses) { section in
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.id)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    ForEach(section.expenses) { expense in
                        SwipeToDeleteRow(
                            isRevealed: Binding(
                                get: { swipedExpenseID == expense.persistentModelID },
                                set: { revealed in
                                    swipedExpenseID = revealed ? expense.persistentModelID : nil
                                }
                            ),
                            onTap: {
                                rowTapped = true
                                selectedExpense = expense
                            },
                            onDelete: {
                                deleteTriggered = true
                                onDelete?(expense)
                            }
                        ) {
                            TransactionRow(expense: expense)
                        }
                    }
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: rowTapped)
        .onChange(of: rowTapped) { _, newValue in if newValue { rowTapped = false } }
        .sheet(item: $selectedExpense) { expense in
            TransactionDetailView(expense: expense)
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
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
            }
            .background(AppColors.expense)
            .clipShape(RoundedRectangle(cornerRadius: 16))
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
                .onTapGesture {
                    if isRevealed {
                        resetSwipe()
                    } else {
                        onTap()
                    }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
    TransactionList(expenses: [
        Expense(amount: 450, category: "Food & Dining", date: Date(), expenseDescription: "Lunch"),
        Expense(amount: 250, category: "Transport", date: Date(), expenseDescription: "Uber")
    ]) { _ in }
    .padding()
}
