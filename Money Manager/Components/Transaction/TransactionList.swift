//
//  TransactionList.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct TransactionList: View {
    let expenses: [Expense]
    @State private var selectedExpense: Expense?
    
    var groupedExpenses: [(String, [Expense])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
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
                        TransactionRow(expense: expense)
                            .onTapGesture {
                                selectedExpense = expense
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

#Preview {
    TransactionList(expenses: [
        Expense(amount: 450, category: "Food & Dining", date: Date(), expenseDescription: "Lunch"),
        Expense(amount: 250, category: "Transport", date: Date(), expenseDescription: "Uber")
    ])
    .padding()
}
