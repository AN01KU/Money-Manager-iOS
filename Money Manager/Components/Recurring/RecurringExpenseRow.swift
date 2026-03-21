import SwiftUI
import SwiftData

struct RecurringExpenseRow: View {
    @Bindable var expense: RecurringExpense
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    let onTap: () -> Void
    
    private var displayName: String {
        expense.name
    }
    
    private var categoryIcon: String {
        if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == expense.category }) {
            return predefined.icon
        }
        if let custom = customCategories.first(where: { $0.name == expense.category }) {
            return custom.icon
        }
        return "ellipsis.circle.fill"
    }
    
    private var categoryColor: Color {
        if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == expense.category }) {
            return predefined.color
        }
        if let custom = customCategories.first(where: { $0.name == expense.category }) {
            return Color(hex: custom.color)
        }
        return .secondary
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(expense.isActive ? categoryColor.opacity(0.2) : AppColors.grayMedium)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: categoryIcon)
                        .font(.title3)
                        .foregroundStyle(expense.isActive ? categoryColor : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(expense.isActive ? .primary : .secondary)
                    
                    HStack(spacing: 6) {
                        Text(expense.frequency.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(expense.isActive ? AppColors.accentLight : AppColors.grayLight)
                            .foregroundStyle(expense.isActive ? AppColors.accent : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        if !expense.isActive {
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
                    
                    Text(expense.isActive ? "Next: \(expense.nextOccurrence?.relativeString ?? "Unknown")" : "Last: \(expense.lastOccurrence?.shortDateString ?? "Never")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(CurrencyFormatter.format(expense.amount))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(expense.isActive ? AppColors.expense : .secondary)
                    
                    Toggle("", isOn: Binding(
                        get: { expense.isActive },
                        set: { newValue in
                            expense.isActive = newValue
                            expense.updatedAt = Date()
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
        .accessibilityLabel("\(displayName), \(CurrencyFormatter.format(expense.amount)), \(expense.isActive ? "Active" : "Paused")")
    }
}
