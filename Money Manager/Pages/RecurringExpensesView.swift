//
//  RecurringExpensesView.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 15/02/26.
//

import SwiftUI
import SwiftData

struct RecurringExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringExpense.name) private var recurringExpenses: [RecurringExpense]
    
    @State private var showAddSheet = false
    
    private var activeExpenses: [RecurringExpense] {
        recurringExpenses.filter { $0.isActive }
    }
    
    var body: some View {
        Group {
            if activeExpenses.isEmpty {
                EmptyStateView(
                    icon: "arrow.clockwise.circle.fill",
                    title: "No recurring expenses",
                    message: "Add subscriptions and regular bills to track them automatically"
                )
            } else {
                List {
                    ForEach(activeExpenses) { expense in
                        RecurringExpenseRow(expense: expense)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            activeExpenses[index].isActive = false
                            activeExpenses[index].updatedAt = Date()
                        }
                    }
                }
            }
        }
        .navigationTitle("Recurring")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddRecurringExpenseSheet()
        }
    }
}

struct RecurringExpenseRow: View {
    @Bindable var expense: RecurringExpense
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    private var categoryIcon: String {
        if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == expense.category }) {
            return predefined.icon
        }
        if let custom = customCategories.first(where: { $0.name == expense.category }) {
            return custom.icon
        }
        return "ellipsis.circle.fill"
    }
    
    private var categoryColor: Color {
        if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == expense.category }) {
            return predefined.color
        }
        if let custom = customCategories.first(where: { $0.name == expense.category }) {
            return Color(hex: custom.color)
        }
        return .secondary
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: categoryIcon)
                .font(.title2)
                .foregroundColor(categoryColor)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name)
                    .fontWeight(.semibold)
                
                Text(CurrencyFormatter.format(expense.amount))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(expense.frequency.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.teal.opacity(0.1))
                .foregroundColor(.teal)
                .cornerRadius(6)
            
            Toggle("", isOn: Binding(
                get: { expense.isActive },
                set: { newValue in
                    expense.isActive = newValue
                    expense.updatedAt = Date()
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct AddRecurringExpenseSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var selectedCategory: String = ""
    @State private var frequency: String = "monthly"
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var dayOfMonth: Int = 1
    @State private var notes: String = ""
    
    @State private var showCategoryPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let frequencies = ["daily", "weekly", "monthly", "yearly"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name *")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g., Netflix, Rent", text: $name)
                            .textInputAutocapitalization(.sentences)
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount *")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            QuickAmountButton(amount: 100) {
                                amount = "100"
                            }
                            QuickAmountButton(amount: 500) {
                                amount = "500"
                            }
                            QuickAmountButton(amount: 1000) {
                                amount = "1000"
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category *")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showCategoryPicker = true
                        }) {
                            HStack {
                                if let category = PredefinedCategory.allCases.first(where: { $0.rawValue == selectedCategory }) {
                                    Image(systemName: category.icon)
                                        .foregroundColor(category.color)
                                    Text(selectedCategory)
                                } else {
                                    Text(selectedCategory.isEmpty ? "Select Category" : selectedCategory)
                                        .foregroundColor(selectedCategory.isEmpty ? .secondary : .primary)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Frequency")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Frequency", selection: $frequency) {
                            ForEach(frequencies, id: \.self) { freq in
                                Text(freq.capitalized).tag(freq)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 8)
                    
                    if frequency == "monthly" {
                        Picker("Day of Month", selection: $dayOfMonth) {
                            ForEach(1...28, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    Toggle("Set End Date", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }
                
                Section("Details") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                }
            }
            .navigationTitle("Add Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRecurringExpense()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedCategory.isEmpty
    }
    
    private func saveRecurringExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Amount must be greater than 0"
            showError = true
            return
        }
        
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a name"
            showError = true
            return
        }
        
        guard !selectedCategory.isEmpty else {
            errorMessage = "Please select a category"
            showError = true
            return
        }
        
        let recurring = RecurringExpense(
            name: name.trimmingCharacters(in: .whitespaces),
            amount: amountValue,
            category: selectedCategory,
            frequency: frequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            dayOfMonth: frequency == "monthly" ? dayOfMonth : nil
        )
        recurring.notes = notes.isEmpty ? nil : notes
        
        modelContext.insert(recurring)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    NavigationStack {
        RecurringExpensesView()
            .modelContainer(for: RecurringExpense.self)
    }
}
