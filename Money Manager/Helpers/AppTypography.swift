import SwiftUI

/// Single source of truth for typography.
/// Base scale mirrors the design spec (SF Pro on iOS, DM Sans fallback on other platforms).
/// Role aliases map semantic use cases onto the base scale — update aliases here only.
enum AppTypography {

    // MARK: - Base scale (design spec)
    // Sizes and tracking match design token spec exactly.
    static let largeTitle = Font.system(size: 34, weight: .bold)        // tracking: -0.5
    static let title1     = Font.system(size: 28, weight: .bold)        // tracking: -0.5
    static let title2     = Font.system(size: 22, weight: .bold)        // tracking: -0.3
    static let title3     = Font.system(size: 20, weight: .semibold)    // tracking: -0.2
    static let headline   = Font.system(size: 17, weight: .semibold)
    static let body       = Font.system(size: 17, weight: .regular)
    static let callout    = Font.system(size: 16, weight: .regular)
    static let subhead    = Font.system(size: 15, weight: .regular)
    static let footnote   = Font.system(size: 13, weight: .regular)     // tracking: +0.1
    static let caption1   = Font.system(size: 12, weight: .regular)
    static let caption2   = Font.system(size: 11, weight: .regular)     // tracking: +0.2

    // MARK: - Tracking (kern) values from design spec
    static let trackingLargeTitle: CGFloat = -0.5
    static let trackingTitle1:     CGFloat = -0.5
    static let trackingTitle2:     CGFloat = -0.3
    static let trackingTitle3:     CGFloat = -0.2
    static let trackingFootnote:   CGFloat =  0.1
    static let trackingCaption2:   CGFloat =  0.2

    // MARK: - Role aliases (map semantic use onto scale)

    // List rows
    static let rowPrimary    = headline
    static let rowSecondary  = subhead
    static let rowMeta       = footnote

    // Amounts
    static let amount        = headline
    static let amountLarge   = title2
    static let amountHero    = Font.system(size: 38, weight: .bold, design: .rounded)

    // Detail / info rows
    static let infoLabel     = subhead
    static let infoValue     = Font.system(size: 15, weight: .medium)

    // Cards / header
    static let cardLabel     = caption1
    static let cardValue     = Font.system(size: 15, weight: .bold)
    static let cardMeta      = caption2

    // Section headers
    static let sectionHeader = Font.system(size: 13, weight: .semibold)

    // Hero / page title area
    static let heroCategory  = subhead
    static let heroDate      = subhead

    // Badges / chips
    static let chip          = subhead
    static let chipSelected  = Font.system(size: 15, weight: .semibold)
    static let badgeIcon     = Font.system(size: 8, weight: .semibold)

    // Buttons
    static let button        = Font.system(size: 16, weight: .semibold)
    static let buttonSmall   = Font.system(size: 14, weight: .semibold)

    // Misc
    static let destructiveIcon = title3
}
