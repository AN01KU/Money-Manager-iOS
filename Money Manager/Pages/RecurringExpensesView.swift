import SwiftUI
import SwiftData

struct RecurringExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Expense> { $0.isRecurring }, sort: \Expense.expenseDescription)
    private var recurringExpenses: [Expense]
    
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.impact(.light)
                                viewModel.editingExpense = expense
                            }
                    }
                    .onDelete { indexSet in
                        HapticManager.notification(.warning)
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
                    HapticManager.impact(.medium)
                    viewModel.showAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddRecurringExpenseSheet()
        }
        .sheet(item: $viewModel.editingExpense) { expense in
            EditRecurringExpenseSheet(expense: expense)
        }
        .onAppear {
            viewModel.configure(expenses: recurringExpenses, modelContext: modelContext)
        }
        .onChange(of: recurringExpenses) { _, _ in
            viewModel.configure(expenses: recurringExpenses, modelContext: modelContext)
        }
    }
}

struct RecurringExpenseRow: View {
    @Bindable var expense: Expense
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    private var displayName: String {
        expense.expenseDescription ?? expense.category
    }
    
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
                Text(displayName)
                    .fontWeight(.semibold)
                
                Text(CurrencyFormatter.format(expense.amount))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let frequency = expense.frequency {
                Text(frequency.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.teal.opacity(0.1))
                    .foregroundColor(.teal)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            Toggle("", isOn: Binding(
                get: { expense.isActive },
                set: { newValue in
                    expense.isActive = newValue
                    expense.updatedAt = Date()
                }
            ))
            .labelsHidden()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
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
                                HapticManager.impact(.light); viewModel.amount = "100"
                            }
                            QuickAmountButton(amount: 500) {
                                HapticManager.impact(.light); viewModel.amount = "500"
                            }
                            QuickAmountButton(amount: 1000) {
                                HapticManager.impact(.light); viewModel.amount = "1000"
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category *")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            HapticManager.impact(.light)
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
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
                            HapticManager.notification(.success)
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
            .modelContainer(for: Expense.self)
    }
}

struct EditRecurringExpenseSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var expense: Expense

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

    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedCategory.isEmpty
    }

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
                    }
                    .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category *")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button(action: {
                            HapticManager.impact(.light)
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
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
            .navigationTitle("Edit Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
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
            .onAppear {
                loadExpenseData()
            }
        }
    }

    private func loadExpenseData() {
        name = expense.expenseDescription ?? ""
        amount = String(format: "%.2f", expense.amount)
        selectedCategory = expense.category
        frequency = expense.frequency ?? "monthly"
        startDate = expense.date
        hasEndDate = expense.recurringEndDate != nil
        endDate = expense.recurringEndDate ?? Date()
        dayOfMonth = expense.dayOfMonth ?? 1
        notes = expense.notes ?? ""
    }

    private func save() {
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

        expense.expenseDescription = name.trimmingCharacters(in: .whitespaces)
        expense.amount = amountValue
        expense.category = selectedCategory
        expense.frequency = frequency
        expense.date = startDate
        expense.dayOfMonth = frequency == "monthly" ? dayOfMonth : nil
        expense.recurringEndDate = hasEndDate ? endDate : nil
        expense.notes = notes.isEmpty ? nil : notes
        expense.updatedAt = Date()

        do {
            try modelContext.save()
            HapticManager.notification(.success)
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}
