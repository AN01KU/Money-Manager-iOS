import SwiftUI

enum AppColors {
    // MARK: - Brand
    static let accent = Color.teal
    static let accentLight = Color.teal.opacity(0.1)
    static let accentSubtle = Color.teal.opacity(0.12)

    // MARK: - Semantic
    static let expense = Color.red
    static let positive = Color.green
    static let warning = Color.orange
    static let info = Color.blue

    // MARK: - Budget Status
    static let budgetSafe = Color.green
    static let budgetCaution = Color.orange
    static let budgetDanger = Color.red

    // MARK: - Grays
    static let grayLight = Color.gray.opacity(0.1)
    static let graySubtle = Color.gray.opacity(0.12)
    static let grayMedium = Color.gray.opacity(0.2)

    // MARK: - Backgrounds
    static let backgroundPrimary = Color.primary.opacity(0.0)
    static let backgroundSecondary = Color.primary.opacity(0.05)
}
