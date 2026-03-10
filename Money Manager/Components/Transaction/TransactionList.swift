//
//  TransactionList.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI
import SwiftData

struct TransactionList: View {
    let expenses: [Expense]
    @State private var selectedExpense: Expense?
    @State private var swipedExpenseID: PersistentIdentifier?
    var onDelete: ((Expense) -> Void)?
    
    var groupedExpenses: [(String, [Expense])] {
        let calendar = Calendar.current
        
        var grouped: [String: [Expense]] = [:]
        
        for expense in expenses {
            let expenseDate = calendar.startOfDay(for: expense.date)
            let key: String
            
            if calendar.isDateInToday(expenseDate) {
                key = "TODAY"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM dd"
                key = formatter.string(from: expenseDate).uppercased()
            }
            
            if grouped[key] == nil {
                grouped[key] = []
            }
            grouped[key]?.append(expense)
        }
        
        return grouped.sorted { first, second in
            if first.key == "TODAY" { return true }
            if second.key == "TODAY" { return false }
            return first.key > second.key
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(groupedExpenses, id: \.0) { section in
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.0)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    ForEach(section.1) { expense in
                        SwipeToDeleteRow(
                            isRevealed: Binding(
                                get: { swipedExpenseID == expense.persistentModelID },
                                set: { revealed in
                                    swipedExpenseID = revealed ? expense.persistentModelID : nil
                                }
                            ),
                            onTap: {
                                HapticManager.impact(.light)
                                selectedExpense = expense
                            },
                            onDelete: {
                                HapticManager.notification(.warning)
                                onDelete?(expense)
                            }
                        ) {
                            TransactionRow(expense: expense)
                        }
                    }
                }
            }
        }
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
                    .foregroundColor(.white)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
            }
            .background(Color.red)
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
