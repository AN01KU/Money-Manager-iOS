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
    @Environment(\.budgetRepository) private var budgetRepository

    @State private var budgetAmount: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var errorTriggered = 0
    @State private var successTriggered = 0
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
                            .accessibilityIdentifier("budget.amount-field")
                    }
                } header: {
                    Text("Monthly Budget Amount")
                } footer: {
                    Text("Set your spending limit. Applies across all months.")
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
            .dismissKeyboardOnScroll()
            .navigationTitle("Set Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("budget.cancel-button")
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
                        .accessibilityIdentifier("budget.save-button")
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: showError) { _, show in
                if show { errorTriggered += 1 }
            }
            .sensoryFeedback(.error, trigger: errorTriggered)
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
        if let existing = budgetRepository.currentBudget(), let limit = existing.limit {
            budgetAmount = limit.formatted(.number.precision(.fractionLength(0)))
        }
    }

    private func saveBudget() {
        guard let amount = Double(budgetAmount), amount > 0 else { return }

        isSaving = true
        do {
            try budgetRepository.setLimit(amount)
            isSaving = false
            successTriggered += 1
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isSaving = false
        }
    }
}

#Preview {
    BudgetSheet()
        .modelContainer(for: [MonthlyBudget.self, UserBudget.self])
}
