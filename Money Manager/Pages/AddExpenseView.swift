import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    @State private var viewModel: AddExpenseViewModel
    
    init(mode: AddExpenseMode = .personal()) {
        _viewModel = State(wrappedValue: AddExpenseViewModel(mode: mode))
    }
    
    init(expenseToEdit: Expense) {
        _viewModel = State(wrappedValue: AddExpenseViewModel(mode: .personal(editing: expenseToEdit)))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                amountSection
                dateTimeSection
                detailsSection
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { viewModel.save { HapticManager.notification(.success); dismiss() } }
                            .fontWeight(.semibold)
                            .disabled(!viewModel.isValid)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCategoryPicker) {
                CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
            }
            .sheet(isPresented: $viewModel.showDatePicker) {
                DatePickerSheet(selectedDate: $viewModel.selectedDate)
            }
            .sheet(isPresented: $viewModel.showTimePicker) {
                TimePickerSheet(selectedTime: $viewModel.selectedTime)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onChange(of: viewModel.showError) { _, show in
                if show { HapticManager.notification(.error) }
            }
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
        }
    }
    
    private var amountSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount *")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextField("0.00", text: $viewModel.amount)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    QuickAmountButton(amount: 100) { HapticManager.impact(.light); viewModel.amount = "100" }
                    QuickAmountButton(amount: 500) { HapticManager.impact(.light); viewModel.amount = "500" }
                    QuickAmountButton(amount: 1000) { HapticManager.impact(.light); viewModel.amount = "1000" }
                }
            }
            .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Category *")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button(action: { HapticManager.impact(.light); viewModel.showCategoryPicker = true }) {
                    HStack {
                        if let custom = customCategories.first(where: { $0.name == viewModel.selectedCategory && !$0.isHidden }) {
                            Image(systemName: custom.icon)
                                .foregroundStyle(Color(hex: custom.color))
                            Text(viewModel.selectedCategory)
                        } else if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == viewModel.selectedCategory }) {
                            Image(systemName: predefined.icon)
                                .foregroundStyle(predefined.color)
                            Text(viewModel.selectedCategory)
                        } else {
                            Text(viewModel.selectedCategory.isEmpty ? "Select Category" : viewModel.selectedCategory)
                                .foregroundStyle(viewModel.selectedCategory.isEmpty ? .secondary : .primary)
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
    }
    
    private var dateTimeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Date *")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button(action: { HapticManager.impact(.light); viewModel.showDatePicker = true }) {
                    HStack {
                        Text(viewModel.formatDate(viewModel.selectedDate))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                HStack(spacing: 12) {
                    QuickDateButton(label: "Today") { HapticManager.impact(.light); viewModel.selectedDate = Date() }
                    QuickDateButton(label: "Yesterday") {
                        HapticManager.impact(.light)
                        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                    }
                }
            }
            .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Include Time", isOn: $viewModel.hasTime)
                
                if viewModel.hasTime {
                    Button(action: { HapticManager.impact(.light); viewModel.showTimePicker = true }) {
                        HStack {
                            Text(viewModel.formatTime(viewModel.selectedTime))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var detailsSection: some View {
        Group {
            Section("Details") {
                TextField("Description (e.g., Lunch at cafe)", text: $viewModel.description)
                    .textInputAutocapitalization(.sentences)
                
                TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.sentences)
            }
        }
    }
}

// MARK: - Shared Components

struct QuickAmountButton: View {
    let amount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(CurrencyFormatter.currentSymbol)\(amount)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppColors.accentLight)
                .foregroundStyle(AppColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.borderless)
    }
}

struct QuickDateButton: View {
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppColors.accentLight)
                .foregroundStyle(AppColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.borderless)
    }
}

struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategory: String
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    private var visiblePredefined: [CustomCategory] {
        customCategories.filter { $0.isPredefined && !$0.isHidden }
    }
    
    private var visibleCustom: [CustomCategory] {
        customCategories.filter { !$0.isPredefined && !$0.isHidden }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !visibleCustom.isEmpty {
                    Section("Your Categories") {
                        ForEach(visibleCustom) { category in
                            CategoryPickerRow(category: category, selectedCategory: selectedCategory) {
                                HapticManager.selection()
                                selectedCategory = category.name
                                dismiss()
                            }
                        }
                    }
                }
                
                Section("Default Categories") {
                    ForEach(visiblePredefined) { category in
                        CategoryPickerRow(category: category, selectedCategory: selectedCategory) {
                            HapticManager.selection()
                            selectedCategory = category.name
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct CategoryPickerRow: View {
    let category: CustomCategory
    let selectedCategory: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(Color(hex: category.color))
                    .frame(width: 30)
                Text(category.name)
                Spacer()
                if selectedCategory == category.name {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
        .foregroundStyle(.primary)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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
                    .datePickerStyle(.graphical)
                    .padding()
                Spacer()
            }
            .navigationTitle("Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("New Expense") {
    AddExpenseView()
        .modelContainer(for: [Expense.self, CustomCategory.self], inMemory: true)
}

#Preview("Edit Expense") {
    let expense = Expense(amount: 450, category: "Food & Dining", date: Date(), expenseDescription: "Lunch at cafe", notes: "With colleagues")
    AddExpenseView(expenseToEdit: expense)
        .modelContainer(for: [Expense.self, CustomCategory.self], inMemory: true)
}
