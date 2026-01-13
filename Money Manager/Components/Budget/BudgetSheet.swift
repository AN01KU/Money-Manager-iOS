//
//  BudgetSheet.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI
import SwiftData

struct BudgetSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let selectedMonth: Date
    @State private var budgetAmount: String = ""
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("₹")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        TextField("0", text: $budgetAmount)
                            .keyboardType(.numberPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .focused($isAmountFocused)
                    }
                } header: {
                    Text("Monthly Budget Amount")
                } footer: {
                    Text("Set your monthly spending limit for \(formatMonth(selectedMonth))")
                }
                
                if let amount = Double(budgetAmount), amount > 0 {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Budget Preview")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(CurrencyFormatter.format(amount))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("Set Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudget()
                    }
                    .fontWeight(.semibold)
                    .disabled(budgetAmount.isEmpty || Double(budgetAmount) == nil || Double(budgetAmount)! <= 0)
                }
            }
            .onAppear {
                loadExistingBudget()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAmountFocused = true
                }
            }
        }
    }
    
    private func loadExistingBudget() {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedMonth)
        let month = calendar.component(.month, from: selectedMonth)
        
        if let existing = try? modelContext.fetch(FetchDescriptor<MonthlyBudget>(
            predicate: #Predicate<MonthlyBudget> { budget in
                budget.year == year && budget.month == month
            }
        )).first {
            budgetAmount = String(format: "%.0f", existing.limit)
        }
    }
    
    private func saveBudget() {
        guard let amount = Double(budgetAmount), amount > 0 else { return }
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedMonth)
        let month = calendar.component(.month, from: selectedMonth)
        
        if let existing = try? modelContext.fetch(FetchDescriptor<MonthlyBudget>(
            predicate: #Predicate<MonthlyBudget> { budget in
                budget.year == year && budget.month == month
            }
        )).first {
            existing.limit = amount
            existing.updatedAt = Date()
        } else {
            let budget = MonthlyBudget(
                year: year,
                month: month,
                limit: amount
            )
            modelContext.insert(budget)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving budget: \(error)")
        }
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    BudgetSheet(selectedMonth: Date())
        .modelContainer(for: [MonthlyBudget.self])
}
