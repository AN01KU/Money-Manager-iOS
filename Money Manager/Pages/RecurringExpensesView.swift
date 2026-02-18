import SwiftUI
import SwiftData

struct RecurringExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringExpense.name) private var recurringExpenses: [RecurringExpense]
    
    @StateObject private var viewModel = RecurringExpensesViewModel()
    
    var body: some View {
        Group {
            if viewModel.activeExpenses.isEmpty {
                EmptyStateView(
                    icon: "arrow.clockwise.circle.fill",
                    title: "No recurring expenses",
                    message: "Add subscriptions and regular bills to track them automatically"
                )
            } else {
                List {
                    ForEach(viewModel.activeExpenses) { expense in
                        RecurringExpenseRow(expense: expense)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deactivateExpense(at: index)
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
                    viewModel.showAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddRecurringExpenseSheet()
        }
        .onAppear {
            viewModel.configure(recurringExpenses: recurringExpenses, modelContext: modelContext)
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
    
    @StateObject private var viewModel = AddRecurringExpenseViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name *")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g., Netflix, Rent", text: $viewModel.name)
                            .textInputAutocapitalization(.sentences)
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount *")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            QuickAmountButton(amount: 100) {
                                viewModel.amount = "100"
                            }
                            QuickAmountButton(amount: 500) {
                                viewModel.amount = "500"
                            }
                            QuickAmountButton(amount: 1000) {
                                viewModel.amount = "1000"
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category *")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            viewModel.showCategoryPicker = true
                        }) {
                            HStack {
                                if let category = PredefinedCategory.allCases.first(where: { $0.rawValue == viewModel.selectedCategory }) {
                                    Image(systemName: category.icon)
                                        .foregroundColor(category.color)
                                    Text(viewModel.selectedCategory)
                                } else {
                                    Text(viewModel.selectedCategory.isEmpty ? "Select Category" : viewModel.selectedCategory)
                                        .foregroundColor(viewModel.selectedCategory.isEmpty ? .secondary : .primary)
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
                        
                        Picker("Frequency", selection: $viewModel.frequency) {
                            ForEach(viewModel.frequencies, id: \.self) { freq in
                                Text(freq.capitalized).tag(freq)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 8)
                    
                    if viewModel.frequency == "monthly" {
                        Picker("Day of Month", selection: $viewModel.dayOfMonth) {
                            ForEach(1...28, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                    }
                    
                    DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    Toggle("Set End Date", isOn: $viewModel.hasEndDate)
                    
                    if viewModel.hasEndDate {
                        DatePicker("End Date", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }
                
                Section("Details") {
                    TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
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
                        if viewModel.save() {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid)
                }
            }
            .sheet(isPresented: $viewModel.showCategoryPicker) {
                CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecurringExpensesView()
            .modelContainer(for: RecurringExpense.self)
    }
}
