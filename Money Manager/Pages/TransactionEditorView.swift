import SwiftUI
import SwiftData

struct TransactionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.persistence) private var persistence
    @Query(sort: \Category.name) private var customCategories: [Category]

    @State private var viewModel: TransactionEditorViewModel

    @State private var errorTriggered = 0

    init(mode: EditorMode = .create) {
        _viewModel = State(wrappedValue: TransactionEditorViewModel(mode: mode))
    }

    var body: some View {
        NavigationStack {
            personalScrollView
        }
        .task { viewModel.persistence = persistence }
        .alert("Update Recurring Transaction?", isPresented: $viewModel.showRecurringAmountAlert) {
            Button("Update Recurring Too") {
                viewModel.saveAlsoUpdatingRecurring { dismiss() }
            }
            Button("Just This Transaction", role: .cancel) {
                viewModel.saveThisTransactionOnly { dismiss() }
            }
        } message: {
            Text("You've changed fields that are part of the recurring schedule. Update the template too?")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sensoryFeedback(.error, trigger: errorTriggered)
        .onChange(of: viewModel.errorMessage) { _, newVal in
            if newVal != nil { errorTriggered += 1 }
        }
    }

    // MARK: - Personal (card-based ScrollView)

    private var personalScrollView: some View {
        ScrollView {
            VStack(spacing: AppConstants.UI.spacing20) {
                AmountCard(viewModel: viewModel)
                typeSegment
                DateRow(viewModel: viewModel)
                detailsCard
                RecurringSection(viewModel: viewModel)
            }
            .padding(.horizontal, AppConstants.UI.padding)
            .padding(.top, AppConstants.UI.spacing12)
            .padding(.bottom, AppConstants.UI.spacingXL)
        }
        .background(AppColors.background)
        .dismissKeyboardOnScroll()
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(viewModel.navigationTitleIdentifier)
        .toolbar { personalToolbar }
        .navigationDestination(isPresented: $viewModel.showCategoryPicker) {
            CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
        }
        .task { viewModel.customCategories = customCategories }
        .onChange(of: customCategories) { _, newValue in viewModel.customCategories = newValue }
    }

    // MARK: - Type segment

    private var typeSegment: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                let selected = viewModel.transactionType == type
                Button {
                    viewModel.transactionType = type
                } label: {
                    Text(type.rawValue)
                        .font(AppTypography.body)
                        .fontWeight(selected ? .semibold : .regular)
                        .foregroundStyle(selected ? AppColors.label : AppColors.label2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            selected
                                ? RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius - 2)
                                    .fill(AppColors.surface)
                                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(AppColors.surface2)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
    }

    // MARK: - Details card

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
            Text("DETAILS")
                .font(AppTypography.footnote)
                .fontWeight(.semibold)
                .tracking(AppTypography.trackingFootnote)
                .foregroundStyle(AppColors.label2)
                .padding(.leading, AppConstants.UI.spacingXS)

            TxnCard {
                VStack(spacing: 0) {
                    TextField(
                        viewModel.isRecurring ? "Name * (e.g., Rent, Netflix)" : "Description (e.g., Lunch at cafe)",
                        text: $viewModel.description
                    )
                    .font(AppTypography.body)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityIdentifier("description-field")

                    Divider().padding(.vertical, AppConstants.UI.spacingSM)

                    TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                        .font(AppTypography.body)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                }
            }
        }
    }

    // MARK: - Toolbar

    private var personalToolbar: some ToolbarContent {
        EditorToolbar(
            isSaving: viewModel.isSaving,
            isValid: viewModel.canSave,
            onCancel: { dismiss() },
            onSave: { viewModel.save { dismiss() } }
        )
    }
}

// MARK: - Previews

#Preview("New Transaction") {
    TransactionEditorView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}

#Preview("Edit Transaction") {
    let transaction = Transaction(amount: 450, category: "food-dining", date: Date(),
                                  transactionDescription: "Lunch at cafe", notes: "With colleagues")
    TransactionEditorView(mode: .edit(transaction))
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
