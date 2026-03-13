import SwiftUI
import SwiftData

struct RecurringExpensesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringExpense.name)
    private var recurringExpenses: [RecurringExpense]
    
    @State private var viewModel = RecurringExpensesViewModel()
    
    var body: some View {
        Group {
            if viewModel.allRecurringExpenses.isEmpty {
                EmptyStateView(
                    icon: "arrow.clockwise.circle.fill",
                    title: "No recurring expenses",
                    message: "Add subscriptions and regular bills to track them automatically"
                )
            } else {
                List {
                    if !viewModel.activeExpenses.isEmpty {
                        Section("Active") {
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
                    
                    if !viewModel.pausedExpenses.isEmpty {
                        Section("Paused") {
                            ForEach(viewModel.pausedExpenses) { expense in
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
                                    viewModel.deactivateExpense(at: index + viewModel.activeExpenses.count)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Recurring")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
        .onChange(of: recurringExpenses) { _, newValue in
            viewModel.configure(expenses: newValue, modelContext: modelContext)
        }
    }
}

struct RecurringExpenseRow: View {
    @Bindable var expense: RecurringExpense
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    private var displayName: String {
        expense.name
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
            ZStack {
                Circle()
                    .fill(expense.isActive ? categoryColor.opacity(0.2) : AppColors.grayMedium)
                    .frame(width: 48, height: 48)
                
                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundStyle(expense.isActive ? categoryColor : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(expense.isActive ? .primary : .secondary)
                
                HStack(spacing: 6) {
                    Text(expense.frequency.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(expense.isActive ? AppColors.accentLight : AppColors.grayLight)
                        .foregroundStyle(expense.isActive ? AppColors.accent : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    if !expense.isActive {
                        Text("Paused")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.warning.opacity(0.1))
                            .foregroundStyle(AppColors.warning)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                
                Text(expense.isActive ? "Next: \(expense.nextOccurrence?.relativeString ?? "Unknown")" : "Last: \(expense.lastOccurrence?.shortDateString ?? "Never")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text(CurrencyFormatter.format(expense.amount))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(expense.isActive ? AppColors.expense : .secondary)
                
                Toggle("", isOn: Binding(
                    get: { expense.isActive },
                    set: { newValue in
                        expense.isActive = newValue
                        expense.updatedAt = Date()
                    }
                ))
                .labelsHidden()
                .tint(AppColors.accent)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
    }
}

struct AddRecurringExpenseSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel = AddRecurringExpenseViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name *")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("e.g., Netflix, Rent", text: $viewModel.name)
                            .textInputAutocapitalization(.sentences)
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount *")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
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
                            .foregroundStyle(.secondary)
                        
                        Button(action: {
                            HapticManager.impact(.light)
                            viewModel.showCategoryPicker = true
                        }) {
                            HStack {
                                if !viewModel.selectedCategory.isEmpty {
                                    Text(viewModel.selectedCategory)
                                } else {
                                    Text("Select Category")
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(.secondary)
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
                            .foregroundStyle(.secondary)
                        
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
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
            .modelContainer(for: RecurringExpense.self)
    }
}

struct EditRecurringExpenseSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var expense: RecurringExpense

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
                            .foregroundStyle(.secondary)

                        TextField("e.g., Netflix, Rent", text: $name)
                            .textInputAutocapitalization(.sentences)
                    }
                    .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount *")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category *")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button(action: {
                            HapticManager.impact(.light)
                            showCategoryPicker = true
                        }) {
                            HStack {
                                if !selectedCategory.isEmpty {
                                    Text(selectedCategory)
                                } else {
                                    Text("Select Category")
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(.secondary)
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
                            .foregroundStyle(.secondary)

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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
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
        name = expense.name
        amount = String(format: "%.2f", expense.amount)
        selectedCategory = expense.category
        frequency = expense.frequency
        startDate = expense.startDate
        hasEndDate = expense.endDate != nil
        endDate = expense.endDate ?? Date()
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

        expense.name = name.trimmingCharacters(in: .whitespaces)
        expense.amount = amountValue
        expense.category = selectedCategory
        expense.frequency = frequency
        expense.startDate = startDate
        expense.dayOfMonth = frequency == "monthly" ? dayOfMonth : nil
        expense.endDate = hasEndDate ? endDate : nil
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
