import SwiftUI

struct AddRecurringExpenseSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel = AddRecurringExpenseViewModel()
    @State private var amount100Tapped = false
    @State private var amount500Tapped = false
    @State private var amount1000Tapped = false
    @State private var categoryTapped = false
    @State private var saveSuccess = false
    
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
                                amount100Tapped = true
                                viewModel.amount = "100"
                            }
                            .sensoryFeedback(.impact(weight: .light), trigger: amount100Tapped)
                            .onChange(of: amount100Tapped) { _, newValue in
                                if newValue { amount100Tapped = false }
                            }
                            
                            QuickAmountButton(amount: 500) {
                                amount500Tapped = true
                                viewModel.amount = "500"
                            }
                            .sensoryFeedback(.impact(weight: .light), trigger: amount500Tapped)
                            .onChange(of: amount500Tapped) { _, newValue in
                                if newValue { amount500Tapped = false }
                            }
                            
                            QuickAmountButton(amount: 1000) {
                                amount1000Tapped = true
                                viewModel.amount = "1000"
                            }
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
                        
                        Button(action: {
                            categoryTapped = true
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
                        .sensoryFeedback(.impact(weight: .light), trigger: categoryTapped)
                        .onChange(of: categoryTapped) { _, newValue in
                            if newValue { categoryTapped = false }
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
                            saveSuccess = true
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
            .sensoryFeedback(.success, trigger: saveSuccess)
            .onChange(of: saveSuccess) { _, newValue in
                if newValue { saveSuccess = false }
            }
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
        }
    }
}
