import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: AddExpenseViewModel
    
    init(mode: AddExpenseMode = .personal()) {
        _viewModel = StateObject(wrappedValue: AddExpenseViewModel(mode: mode))
    }
    
    init(expenseToEdit: Expense) {
        _viewModel = StateObject(wrappedValue: AddExpenseViewModel(mode: .personal(editing: expenseToEdit)))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                mainSection
                
                if viewModel.isShared {
                    paidBySection
                    splitSection
                    splitMembersSection
                    if viewModel.splitType == .custom && !viewModel.selectedMembers.isEmpty {
                        splitSummarySection
                    }
                } else {
                    dateTimeSection
                    detailsSection
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { viewModel.save { dismiss() } }
                            .fontWeight(.semibold)
                            .disabled(!viewModel.isValid)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCategoryPicker) {
                if viewModel.isShared {
                    sharedCategoryPicker
                } else {
                    CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
                }
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
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
        }
    }
    
    private var mainSection: some View {
        Section {
            if viewModel.isShared {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description *")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Dinner, Cab, Groceries", text: $viewModel.description)
                        .textInputAutocapitalization(.sentences)
                }
                .padding(.vertical, 4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount *")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $viewModel.amount)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    QuickAmountButton(amount: 100) { viewModel.amount = "100" }
                    QuickAmountButton(amount: 500) { viewModel.amount = "500" }
                    QuickAmountButton(amount: 1000) { viewModel.amount = "1000" }
                }
            }
            .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Category *")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: { viewModel.showCategoryPicker = true }) {
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
    }
    
    private var dateTimeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Date *")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: { viewModel.showDatePicker = true }) {
                    HStack {
                        Text(viewModel.formatDate(viewModel.selectedDate))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                HStack(spacing: 12) {
                    QuickDateButton(label: "Today") { viewModel.selectedDate = Date() }
                    QuickDateButton(label: "Yesterday") {
                        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                    }
                }
            }
            .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Include Time", isOn: $viewModel.hasTime)
                
                if viewModel.hasTime {
                    Button(action: { viewModel.showTimePicker = true }) {
                        HStack {
                            Text(viewModel.formatTime(viewModel.selectedTime))
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
            
            Section {
                Toggle("Make this recurring?", isOn: $viewModel.isRecurring)
            }
        }
    }
    
    private var paidBySection: some View {
        Section("Paid By") {
            if case .shared(_, let members, _) = viewModel.mode {
                ForEach(members) { member in
                    Button { viewModel.paidByUserId = member.id } label: {
                        HStack {
                            Text(viewModel.displayName(for: member))
                                .foregroundColor(.primary)
                            Text(member.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: viewModel.paidByUserId == member.id ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(viewModel.paidByUserId == member.id ? .teal : .secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var splitSection: some View {
        Section {
            Picker("Split Type", selection: $viewModel.splitType) {
                ForEach(SplitType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Split Between")
        }
    }
    
    private var splitMembersSection: some View {
        Section {
            if case .shared(_, let members, _) = viewModel.mode {
                ForEach(members) { member in
                    HStack {
                        Button { viewModel.toggleMember(member.id) } label: {
                            HStack {
                                Image(systemName: viewModel.selectedMembers.contains(member.id) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(viewModel.selectedMembers.contains(member.id) ? .teal : .secondary)
                                Text(viewModel.displayName(for: member))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                        
                        if viewModel.splitType == .equal {
                            if viewModel.selectedMembers.contains(member.id) {
                                Text(viewModel.equalShareText)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            if viewModel.selectedMembers.contains(member.id) {
                                TextField("0.00", text: viewModel.binding(for: member.id))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var splitSummarySection: some View {
        Section {
            HStack {
                Text("Total split")
                    .foregroundColor(.secondary)
                Spacer()
                Text(CurrencyFormatter.format(viewModel.customSplitTotal, showDecimals: true))
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.splitMatchesTotal ? .green : .red)
            }
            
            if let total = Double(viewModel.amount), total > 0 {
                HStack {
                    Text("Remaining")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.format(total - viewModel.customSplitTotal, showDecimals: true))
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.splitMatchesTotal ? .green : .orange)
                }
            }
        }
    }
    
    private var sharedCategoryPicker: some View {
        NavigationStack {
            List {
                ForEach(PredefinedCategory.allCases) { category in
                    Button {
                        viewModel.selectedCategory = category.rawValue
                        viewModel.showCategoryPicker = false
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                                .frame(width: 30)
                            Text(category.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if viewModel.selectedCategory == category.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.teal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { viewModel.showCategoryPicker = false }
                }
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
        Button(action: action) {
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
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    private var visibleCustom: [CustomCategory] {
        customCategories.filter { !$0.isHidden }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !visibleCustom.isEmpty {
                    Section("Your Categories") {
                        ForEach(visibleCustom) { category in
                            Button {
                                selectedCategory = category.name
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundColor(Color(hex: category.color))
                                        .frame(width: 30)
                                    Text(category.name)
                                    Spacer()
                                    if selectedCategory == category.name {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.teal)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                Section("Default Categories") {
                    ForEach(PredefinedCategory.allCases) { category in
                        Button {
                            selectedCategory = category.rawValue
                            dismiss()
                        } label: {
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
                    Button("Done") { dismiss() }
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
                    .datePickerStyle(.wheel)
                    .padding()
                Spacer()
            }
            .navigationTitle("Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Personal - New") {
    AddExpenseView()
        .modelContainer(for: [Expense.self, CustomCategory.self], inMemory: true)
}

#Preview("Personal - Edit") {
    let expense = Expense(amount: 450, category: "Food & Dining", date: Date(), expenseDescription: "Lunch at cafe", notes: "With colleagues")
    AddExpenseView(expenseToEdit: expense)
        .modelContainer(for: [Expense.self, CustomCategory.self], inMemory: true)
}

#Preview("Shared - Small Group") {
    let group = TestData.testGroups[0]
    AddExpenseView(mode: .shared(group: group, members: TestData.testGroupMembers[group.id] ?? []) { _ in })
        .modelContainer(for: Expense.self, inMemory: true)
}

#Preview("Shared - Large Group") {
    let group = TestData.testGroups[2]
    AddExpenseView(mode: .shared(group: group, members: TestData.testGroupMembers[group.id] ?? []) { _ in })
        .modelContainer(for: Expense.self, inMemory: true)
}
