import SwiftUI
import SwiftData

struct RecurringTransactionRow: View {
    @Bindable var recurring: RecurringTransaction
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    let onTap: () -> Void

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
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(recurring.isActive ? categoryColor.opacity(0.2) : AppColors.grayMedium)
                        .frame(width: 48, height: 48)

                    Image(systemName: categoryIcon)
                        .font(.title3)
                        .foregroundStyle(recurring.isActive ? categoryColor : .secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(recurring.isActive ? .primary : .secondary)

                    HStack(spacing: 6) {
                        Text(recurring.frequency.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(recurring.isActive ? AppColors.accentLight : AppColors.grayLight)
                            .foregroundStyle(recurring.isActive ? AppColors.accent : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        if !recurring.isActive {
                            Text("Paused")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.warning.opacity(0.1))
                                .foregroundStyle(AppColors.warning)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    Text(recurring.isActive ? "Next: \(recurring.nextOccurrence?.relativeString ?? "Unknown")" : "Last: \(recurring.lastOccurrence?.shortDateString ?? "Never")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(CurrencyFormatter.format(recurring.amount))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(recurring.isActive ? AppColors.expense : .secondary)

                    Toggle("", isOn: Binding(
                        get: { recurring.isActive },
                        set: { newValue in
                            recurring.isActive = newValue
                            recurring.updatedAt = Date()
                        }
                    ))
                    .labelsHidden()
                    .tint(AppColors.accent)
                    .accessibilityRemoveTraits(.isButton)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(displayName), \(CurrencyFormatter.format(recurring.amount)), \(recurring.isActive ? "Active" : "Paused")")
    }
}
