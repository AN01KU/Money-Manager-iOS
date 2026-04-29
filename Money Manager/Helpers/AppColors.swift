import SwiftUI

/// All colors must be consumed from here — never use raw hex or Color literals in views.
/// Light/dark variants are resolved automatically via the asset catalog.
enum AppColors {

    // MARK: - Brand
    /// #17C5CC — buttons, active states, FAB
    static let primary    = Color("Primary", bundle: .main)
    /// Tinted chip/row backgrounds
    static let primaryBg  = Color("PrimaryBg", bundle: .main)

    // MARK: - Semantic
    /// Positive amounts, in-budget indicators
    static let income     = Color("Income", bundle: .main)
    /// Income badge background
    static let incomeBg   = Color("IncomeBg", bundle: .main)
    /// Negative amounts, over-budget indicators
    static let expense    = Color("Expense", bundle: .main)
    /// Expense badge background
    static let expenseBg  = Color("ExpenseBg", bundle: .main)
    /// Near-limit / caution states
    static let warning    = Color("Warning", bundle: .main)

    // MARK: - Backgrounds
    /// Page / system background (light: #F2F2F7 · dark: #000000 OLED)
    static let background = Color("AppBackground", bundle: .main)
    /// Cards, sheets, list rows (light: #FFFFFF · dark: #1C1C1E)
    static let surface    = Color("Surface", bundle: .main)
    /// Nested / grouped lists (light: #F2F2F7 · dark: #2C2C2E)
    static let surface2   = Color("Surface2", bundle: .main)

    // MARK: - Labels
    /// Primary text (light: #000000 · dark: #FFFFFF)
    static let label      = Color("Label", bundle: .main)
    /// Secondary text (light: #8E8E93 · dark: 60% white)
    static let label2     = Color("Label2", bundle: .main)
    /// Disabled / hint text (light: #C7C7CC · dark: 28% white)
    static let label3     = Color("Label3", bundle: .main)

    // MARK: - Structural
    /// Dividers and row borders
    static let separator  = Color("Separator", bundle: .main)

    // MARK: - Budget status (convenience aliases)
    static let budgetSafe    = income
    static let budgetCaution = warning
    static let budgetDanger  = expense

    // MARK: - Legacy aliases (keep until call sites are migrated to new names)
    static let accent              = primary
    static let accentLight         = primaryBg
    static let accentSubtle        = primaryBg
    static let positive            = income
    static let info                = Color("CatBlue", bundle: .main)
    static let grayLight           = Color(white: 0.5, opacity: 0.10)
    static let graySubtle          = Color(white: 0.5, opacity: 0.12)
    static let grayMedium          = Color(white: 0.5, opacity: 0.20)
    static let backgroundPrimary   = Color.clear
    static let backgroundSecondary = Color.primary.opacity(0.05)
}
