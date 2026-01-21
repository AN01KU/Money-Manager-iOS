//
//  AddExpenseView.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var amount: String = ""
    @State private var selectedCategory: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Date()
    @State private var hasTime: Bool = true
    @State private var description: String = ""
    @State private var notes: String = ""
    @State private var isRecurring: Bool = false
    
    @State private var showCategoryPicker = false
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var expenseToEdit: Expense?
    
    init(expenseToEdit: Expense? = nil) {
        self.expenseToEdit = expenseToEdit
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Amount
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
                    
                    // Category
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
                    
                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date *")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack {
                                Text(formatDate(selectedDate))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        HStack(spacing: 12) {
                            QuickDateButton(label: "Today") {
                                selectedDate = Date()
                            }
                            QuickDateButton(label: "Yesterday") {
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Time
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Include Time", isOn: $hasTime)
                        
                        if hasTime {
                            Button(action: {
                                showTimePicker = true
                            }) {
                                HStack {
                                    Text(formatTime(selectedTime))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Details") {
                    TextField("Description (e.g., Lunch at cafe)", text: $description)
                        .textInputAutocapitalization(.sentences)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                }
                
                Section {
                    Toggle("Make this recurring?", isOn: $isRecurring)
                }
            }
            .navigationTitle(expenseToEdit == nil ? "Add Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory)
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate)
            }
            .sheet(isPresented: $showTimePicker) {
                TimePickerSheet(selectedTime: $selectedTime)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if let expense = expenseToEdit {
                    loadExpense(expense)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return !selectedCategory.isEmpty
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Amount must be greater than 0"
            showError = true
            return
        }
        
        guard !selectedCategory.isEmpty else {
            errorMessage = "Please select a category"
            showError = true
            return
        }
        
        let calendar = Calendar.current
        var expenseDate = calendar.startOfDay(for: selectedDate)
        
        if hasTime {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
            expenseDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                       minute: timeComponents.minute ?? 0,
                                       second: 0,
                                       of: selectedDate) ?? selectedDate
        }
        
        if let expense = expenseToEdit {
            // Update existing expense
            expense.amount = amountValue
            expense.category = selectedCategory
            expense.date = expenseDate
            expense.time = hasTime ? selectedTime : nil
            expense.expenseDescription = description.isEmpty ? nil : description
            expense.notes = notes.isEmpty ? nil : notes
            expense.updatedAt = Date()
        } else {
            // Create new expense
            let expense = Expense(
                amount: amountValue,
                category: selectedCategory,
                date: expenseDate,
                time: hasTime ? selectedTime : nil,
                expenseDescription: description.isEmpty ? nil : description,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(expense)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save expense: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func loadExpense(_ expense: Expense) {
        amount = String(format: "%.2f", expense.amount)
        selectedCategory = expense.category
        selectedDate = expense.date
        selectedTime = expense.time ?? Date()
        hasTime = expense.time != nil
        description = expense.expenseDescription ?? ""
        notes = expense.notes ?? ""
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct QuickAmountButton: View {
    let amount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text("₹\(amount)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.teal.opacity(0.1))
                .foregroundColor(.teal)
                .cornerRadius(8)
        }
        .buttonStyle(.borderless)
    }
}

struct QuickDateButton: View {
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.teal.opacity(0.1))
                .foregroundColor(.teal)
                .cornerRadius(8)
        }
        .buttonStyle(.borderless)
    }
}

struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategory: String
    
    var body: some View {
        NavigationStack {
            List {
                Section("Predefined Categories") {
                    ForEach(PredefinedCategory.allCases) { category in
                        Button(action: {
                            selectedCategory = category.rawValue
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                    .frame(width: 30)
                                Text(category.rawValue)
                                Spacer()
                                if selectedCategory == category.rawValue {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.teal)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DatePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TimePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTime: Date
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddExpenseView()
}
