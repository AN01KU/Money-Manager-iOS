import SwiftUI

/// Centralised font + color-role constants.
/// When a designer hands over a type scale, update values here only —
/// every view that uses these tokens picks up the change automatically.
enum AppTypography {

    // MARK: - List rows
    static let rowPrimary   = Font.subheadline.weight(.medium)
    static let rowSecondary = Font.caption
    static let rowMeta      = Font.caption2.weight(.medium)

    // MARK: - Amounts
    static let amount       = Font.body.weight(.semibold)
    static let amountHero   = Font.system(size: 38, weight: .bold, design: .rounded)

    // MARK: - Detail / info rows
    static let infoLabel    = Font.subheadline          // left column label
    static let infoValue    = Font.subheadline.weight(.medium) // right column value

    // MARK: - Cards / header
    static let cardLabel    = Font.caption
    static let cardValue    = Font.subheadline.weight(.bold)
    static let cardMeta     = Font.caption2

    // MARK: - Section headers
    static let sectionHeader = Font.subheadline.weight(.semibold)

    // MARK: - Hero / page title area
    static let heroCategory = Font.subheadline          // category name under icon
    static let heroDate     = Font.subheadline          // date under amount

    // MARK: - Badges / chips
    static let chip         = Font.subheadline
    static let chipSelected = Font.subheadline.weight(.semibold)
    static let badgeIcon    = Font.system(size: 8, weight: .semibold)

    // MARK: - Buttons
    static let button       = Font.body.weight(.semibold)

    // MARK: - Delete button icon in list
    static let destructiveIcon = Font.title3
}
