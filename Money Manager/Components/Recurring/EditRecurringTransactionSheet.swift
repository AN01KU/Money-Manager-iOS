import SwiftUI
import SwiftData

struct EditRecurringTransactionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.authService) private var authService
    @Environment(\.changeQueueManager) private var changeQueueManager
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    @Bindable var recurring: RecurringTransaction

    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var selectedCategory: String = ""
    @State private var transactionType: TransactionKind = .expense
    @State private var frequency: RecurringFrequency = .monthly
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var dayOfMonth: Int = 1
    @State private var notes: String = ""
    @State private var showCategoryPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var categoryTapped = 0
    @State private var saveSuccess = 0

    private let frequencies = RecurringFrequency.allCases

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
                            categoryTapped += 1
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
                        .sensoryFeedback(.impact(weight: .light), trigger: categoryTapped)
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Picker("Type", selection: $transactionType) {
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

                        Picker("Frequency", selection: $frequency) {
                            ForEach(frequencies, id: \.self) { freq in
                                Text(freq.rawValue.capitalized).tag(freq)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 8)

                    if frequency == .monthly {
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
            .dismissKeyboardOnScroll()
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
                loadData()
            }
        }
    }

    private func loadData() {
        name = recurring.name
        amount = recurring.amount.editableString
        selectedCategory = recurring.category
        transactionType = recurring.type
        frequency = recurring.frequency
        startDate = recurring.startDate
        hasEndDate = recurring.endDate != nil
        endDate = recurring.endDate ?? Date()
        dayOfMonth = recurring.dayOfMonth ?? 1
        notes = recurring.notes ?? ""
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

        recurring.name = name.trimmingCharacters(in: .whitespaces)
        recurring.amount = amountValue
        recurring.category = selectedCategory
        recurring.categoryId = customCategories.first(where: { $0.name == selectedCategory })?.id
        recurring.type = transactionType
        recurring.frequency = frequency
        recurring.startDate = startDate
        recurring.dayOfMonth = frequency == .monthly ? dayOfMonth : nil
        recurring.endDate = hasEndDate ? endDate : nil
        recurring.notes = notes.isEmpty ? nil : notes
        recurring.updatedAt = Date()

        do {
            try modelContext.save()

            let payload = try? APIClient.apiEncoder.encode(recurring.toUpdateRequest())
            changeQueueManager.enqueue(
                entityType: "recurring",
                entityID: recurring.id,
                action: "update",
                endpoint: "/recurring-transactions",
                httpMethod: "PUT",
                payload: payload,
                context: modelContext
            )

            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueueManager.replayAll(context: modelContext, isAuthenticated: authService.isAuthenticated)
                }
            }

            saveSuccess += 1
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}
