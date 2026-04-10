import SwiftUI
import SwiftData

struct AddRecurringTransactionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    private let prefillAmount: String
    private let prefillCategory: String
    private let prefillType: TransactionKind

    init(prefillAmount: String = "", prefillCategory: String = "", prefillType: TransactionKind = .expense) {
        self.prefillAmount = prefillAmount
        self.prefillCategory = prefillCategory
        self.prefillType = prefillType
    }

    @State private var viewModel = AddRecurringTransactionViewModel()
    @State private var amount100Tapped = 0
    @State private var amount500Tapped = 0
    @State private var amount1000Tapped = 0
    @State private var categoryTapped = 0
    @State private var saveSuccess = 0

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
                                amount100Tapped += 1
                                viewModel.amount = "100"
                            }
                            .sensoryFeedback(.impact(weight: .light), trigger: amount100Tapped)

                            QuickAmountButton(amount: 500) {
                                amount500Tapped += 1
                                viewModel.amount = "500"
                            }
                            .sensoryFeedback(.impact(weight: .light), trigger: amount500Tapped)

                            QuickAmountButton(amount: 1000) {
                                amount1000Tapped += 1
                                viewModel.amount = "1000"
                            }
                            .sensoryFeedback(.impact(weight: .light), trigger: amount1000Tapped)
                        }
                    }
                    .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category *")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button(action: {
                            categoryTapped += 1
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
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Picker("Type", selection: $viewModel.transactionType) {
                        ForEach(TransactionKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue.capitalized).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Frequency")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Picker("Frequency", selection: $viewModel.frequency) {
                            ForEach(viewModel.frequencies, id: \.self) { freq in
                                Text(freq.rawValue.capitalized).tag(freq)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 8)

                    if viewModel.frequency == .monthly {
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
                            saveSuccess += 1
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
            .task {
                viewModel.modelContext = modelContext
                viewModel.customCategories = customCategories
                viewModel.prefill(amount: prefillAmount, category: prefillCategory, type: prefillType)
            }
            .onChange(of: customCategories) { _, newValue in
                viewModel.customCategories = newValue
            }
        }
    }
}
