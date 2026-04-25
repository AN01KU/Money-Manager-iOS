import SwiftUI
import SwiftData

struct RecurringTransactionRow: View {
    let recurring: RecurringTransaction
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    let onTap: () -> Void
    let onToggle: () -> Void

    private var displayName: String {
        recurring.name
    }

    private var categoryIcon: String {
        if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == recurring.category }) {
            return predefined.icon
        }
        if let custom = customCategories.first(where: { $0.name == recurring.category }) {
            return custom.icon
        }
        return "ellipsis.circle.fill"
    }

    private var categoryColor: Color {
        if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == recurring.category }) {
            return predefined.color
        }
        if let custom = customCategories.first(where: { $0.name == recurring.category }) {
            return Color(hex: custom.color)
        }
        return .secondary
    }

    var body: some View {
        if recurring.modelContext == nil {
            EmptyView()
        } else {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: categoryIcon)
                        .foregroundStyle(recurring.isActive ? categoryColor : .secondary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayName)
                            .font(.body)
                            .foregroundStyle(recurring.isActive ? .primary : .secondary)

                        HStack(spacing: 6) {
                            Text(recurring.frequency.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            if !recurring.isActive {
                                Text("Paused")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.warning)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(AppColors.warning.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else if let next = recurring.nextOccurrence {
                                Text("Next: \(next.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(CurrencyFormatter.format(recurring.amount))
                            .font(.body)
                            .foregroundStyle(recurring.isActive ? (recurring.type == .income ? AppColors.income : AppColors.expense) : .secondary)

                        Toggle("", isOn: Binding(
                            get: { recurring.isActive },
                            set: { _ in onToggle() }
                        ))
                        .labelsHidden()
                        .tint(AppColors.accent)
                        .accessibilityRemoveTraits(.isButton)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(displayName), \(CurrencyFormatter.format(recurring.amount)), \(recurring.isActive ? "Active" : "Paused")")
            .accessibilityIdentifier("recurring.row")
        }
    }
}
