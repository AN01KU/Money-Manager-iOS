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
                
                DatePicker("Select Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                
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
                    DatePicker("Select Time", selection: $viewModel.selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
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
