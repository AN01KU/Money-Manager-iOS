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
    @AppStorage("defaultBudgetLimit") private var defaultBudgetLimit: Double = 0
    @State private var budgetAmount: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var errorTriggered = false
    @State private var successTriggered = false
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(CurrencyFormatter.currentSymbol)
                            .font(.title2)
                            .foregroundStyle(.secondary)
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
                                .foregroundStyle(.secondary)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveBudget()
                        }
                        .fontWeight(.semibold)
                        .disabled(budgetAmount.isEmpty || (Double(budgetAmount) ?? 0) <= 0)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: showError) { _, show in
                if show { errorTriggered = true }
            }
            .sensoryFeedback(.error, trigger: errorTriggered)
            .onChange(of: errorTriggered) { _, newValue in
                if newValue { errorTriggered = false }
            }
            .sensoryFeedback(.success, trigger: successTriggered)
            .onAppear {
                loadExistingBudget()
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
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
            budgetAmount = existing.limit.formatted(.number.precision(.fractionLength(0)))
        } else if defaultBudgetLimit > 0 {
            budgetAmount = defaultBudgetLimit.formatted(.number.precision(.fractionLength(0)))
        }
    }
    
    private func saveBudget() {
        guard let amount = Double(budgetAmount), amount > 0 else { return }
        
        isSaving = true
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedMonth)
        let month = calendar.component(.month, from: selectedMonth)
        
        let budgetID: UUID
        let action: String
        let httpMethod: String
        
        if let existing = try? modelContext.fetch(FetchDescriptor<MonthlyBudget>(
            predicate: #Predicate<MonthlyBudget> { budget in
                budget.year == year && budget.month == month
            }
        )).first {
            existing.limit = amount
            existing.updatedAt = Date()
            budgetID = existing.id
            action = "update"
            httpMethod = "PUT"
        } else {
            let budget = MonthlyBudget(
                year: year,
                month: month,
                limit: amount
            )
            modelContext.insert(budget)
            budgetID = budget.id
            action = "create"
            httpMethod = "POST"
        }
        
        defaultBudgetLimit = amount
        
        do {
            try modelContext.save()
            
            let limitString = amount.formatted(.number.precision(.fractionLength(2)))
            let payload: Data? = action == "create"
                ? try? APIClient.apiEncoder.encode(APICreateBudgetRequest(year: year, month: month, limit: limitString))
                : try? APIClient.apiEncoder.encode(APIUpdateBudgetRequest(year: year, month: month, limit: limitString))
            changeQueueManager.enqueue(
                entityType: "budget",
                entityID: budgetID,
                action: action,
                endpoint: "/budgets",
                httpMethod: httpMethod,
                payload: payload,
                context: modelContext
            )
            
            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueueManager.replayAll(context: modelContext)
                }
            }
        } catch {
            errorMessage = "Failed to save budget locally"
            showError = true
            isSaving = false
            return
        }
        
        isSaving = false
        successTriggered = true
        dismiss()
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
