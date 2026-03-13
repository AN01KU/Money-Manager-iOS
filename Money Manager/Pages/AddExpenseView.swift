import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    @State private var viewModel: AddExpenseViewModel
    @State private var amount100Tapped = false
    @State private var amount500Tapped = false
    @State private var amount1000Tapped = false
    @State private var categoryTapped = false
    @State private var dateTapped = false
    @State private var timeTapped = false
    @State private var todayTapped = false
    @State private var saveSuccess = false
    @State private var errorTriggered = false
    @State private var dateSelectionToggled = false
    @State private var timeSelectionToggled = false
    
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
                        Button("Save") { viewModel.save { saveSuccess = true; dismiss() } }
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
                if show { errorTriggered = true }
            }
            .sensoryFeedback(.error, trigger: errorTriggered)
            .onChange(of: errorTriggered) { _, newValue in
                if newValue { errorTriggered = false }
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
                    QuickAmountButton(amount: 100) { amount100Tapped = true; viewModel.amount = "100" }
                    .sensoryFeedback(.impact(weight: .light), trigger: amount100Tapped)
                    .onChange(of: amount100Tapped) { _, newValue in
                        if newValue { amount100Tapped = false }
                    }
                    QuickAmountButton(amount: 500) { amount500Tapped = true; viewModel.amount = "500" }
                    .sensoryFeedback(.impact(weight: .light), trigger: amount500Tapped)
                    .onChange(of: amount500Tapped) { _, newValue in
                        if newValue { amount500Tapped = false }
                    }
                    QuickAmountButton(amount: 1000) { amount1000Tapped = true; viewModel.amount = "1000" }
                    .sensoryFeedback(.impact(weight: .light), trigger: amount1000Tapped)
                    .onChange(of: amount1000Tapped) { _, newValue in
                        if newValue { amount1000Tapped = false }
                    }
                }
            }
            .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Category *")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button(action: { categoryTapped = true; viewModel.showCategoryPicker = true }) {
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
                .sensoryFeedback(.impact(weight: .light), trigger: categoryTapped)
                .onChange(of: categoryTapped) { _, newValue in
                    if newValue { categoryTapped = false }
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
                
                Button(action: { dateTapped = true; viewModel.showDatePicker = true }) {
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
                .sensoryFeedback(.impact(weight: .light), trigger: dateTapped)
                .onChange(of: dateTapped) { _, newValue in
                    if newValue { dateTapped = false }
                }
                
                HStack(spacing: 12) {
                    QuickDateButton(label: "Today") { todayTapped = true; viewModel.selectedDate = Date() }
                    .sensoryFeedback(.impact(weight: .light), trigger: todayTapped)
                    .onChange(of: todayTapped) { _, newValue in
                        if newValue { todayTapped = false }
                    }
                    QuickDateButton(label: "Yesterday") {
                        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                    }
                }
            }
            .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Include Time", isOn: $viewModel.hasTime)
                
                if viewModel.hasTime {
                    Button(action: { timeTapped = true; viewModel.showTimePicker = true }) {
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
                    .sensoryFeedback(.impact(weight: .light), trigger: timeTapped)
                    .onChange(of: timeTapped) { _, newValue in
                        if newValue { timeTapped = false }
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
    @State private var selectionToggled = false
    
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
                                selectionToggled = true
                                selectedCategory = category.name
                                dismiss()
                            }
                            .sensoryFeedback(.selection, trigger: selectionToggled)
                            .onChange(of: selectionToggled) { _, newValue in
                                if newValue { selectionToggled = false }
                            }
                        }
                    }
                }
                
                Section("Default Categories") {
                    ForEach(visiblePredefined) { category in
                        CategoryPickerRow(category: category, selectedCategory: selectedCategory) {
                            selectionToggled = true
                            selectedCategory = category.name
                            dismiss()
                        }
                        .sensoryFeedback(.selection, trigger: selectionToggled)
                        .onChange(of: selectionToggled) { _, newValue in
                            if newValue { selectionToggled = false }
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
