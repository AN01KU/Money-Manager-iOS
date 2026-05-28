import SwiftUI
import SwiftData

struct EditRecurringTransactionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.authService) private var authService
    @Environment(\.changeQueueManager) private var changeQueueManager
    @Environment(\.networkMonitor) private var networkMonitor
    @Query(sort: \Category.name) private var customCategories: [Category]

    @Bindable var recurring: RecurringTransaction

    @State private var viewModel = EditRecurringTransactionViewModel()
    @State private var categoryTapped = 0

    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

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
                            .accessibilityIdentifier("recurring.name-field")
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
                            .accessibilityIdentifier("recurring.amount-field")
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
                                if !viewModel.selectedCategoryName.isEmpty {
                                    Text(viewModel.selectedCategoryName)
                                } else {
                                    Text("Select Category")
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(AppColors.inputBackground)
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
                        .onChange(of: viewModel.frequency) { _, _ in
                            viewModel.validateFrequency()
                        }
                    }
                    .padding(.vertical, 8)

                    if viewModel.frequency == .monthly {
                        Picker("Day of Month", selection: $viewModel.dayOfMonth) {
                            ForEach(1...28, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .onChange(of: viewModel.dayOfMonth) { _, _ in
                            viewModel.validateFrequency()
                        }
                    }

                    if viewModel.frequency == .weekly {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Days of Week")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                ForEach(0..<7, id: \.self) { index in
                                    let selected = viewModel.daysOfWeek.contains(index)
                                    Button(weekdays[index]) {
                                        if selected {
                                            viewModel.daysOfWeek.removeAll { $0 == index }
                                        } else {
                                            viewModel.daysOfWeek.append(index)
                                            viewModel.daysOfWeek.sort()
                                        }
                                        viewModel.validateFrequency()
                                    }
                                    .font(.caption)
                                    .fontWeight(selected ? .semibold : .regular)
                                    .foregroundStyle(selected ? Color.white : Color.primary)
                                    .frame(minWidth: 36, minHeight: 36)
                                    .background(selected ? Color.accentColor : AppColors.chipBackground)
                                    .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if let freqErr = viewModel.frequencyError {
                        Text(freqErr)
                            .font(.caption)
                            .foregroundStyle(.red)
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
            .dismissKeyboardOnScroll()
            .navigationTitle("Edit Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("recurring.cancel-button")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid)
                    .accessibilityIdentifier("recurring.save-button")
                }
            }
            .sheet(isPresented: $viewModel.showCategoryPicker) {
                CategoryPickerView(selectedCategoryId: $viewModel.selectedCategoryId)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.load(from: recurring, categories: customCategories)
            }
            .onChange(of: customCategories) { _, newValue in
                viewModel.customCategories = newValue
            }
        }
    }

    private func save() {
        guard viewModel.apply(to: recurring, categories: customCategories) else { return }

        do {
            try modelContext.save()

            let payload = try? AppAPIClient.apiEncoder.encode(recurring.toUpdateRequest(categories: customCategories))
            changeQueueManager.enqueue(
                PendingChangeDraft(
                    entityType: .recurring,
                    entityID: recurring.id,
                    action: .update,
                    endpoint: "/recurring-transactions",
                    httpMethod: .patch,
                    payload: payload
                ),
                context: modelContext
            )

            if networkMonitor.isConnected {
                Task {
                    await changeQueueManager.replayAll(context: modelContext, isAuthenticated: authService.isAuthenticated)
                }
            }

            dismiss()
        } catch {
            viewModel.errorMessage = "Failed to save: \(error.localizedDescription)"
            viewModel.showError = true
        }
    }
}
