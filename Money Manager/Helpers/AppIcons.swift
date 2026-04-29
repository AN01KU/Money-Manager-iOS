import SwiftUI

/// Asset catalog names for all app icons.
/// Icons are SVG imagesets in Assets.xcassets/Icons/ with template rendering.
///
/// Usage:
///   AppIcon(name: AppIcons.UI.home, size: 24, color: AppColors.primary)
///   AppIcon(name: AppIcons.Category.food, size: 20, color: .white)
enum AppIcons {

    // MARK: - UI / Nav icons
    enum UI {
        static let home         = "Icons/UI/home"
        static let transactions = "Icons/UI/transactions"
        static let groups       = "Icons/UI/groups"
        static let settings     = "Icons/UI/settings"
        static let add          = "Icons/UI/add"
        static let back         = "Icons/UI/back"
        static let chevron      = "Icons/UI/chevron"
        static let search       = "Icons/UI/search"
        static let edit         = "Icons/UI/edit"
        static let delete       = "Icons/UI/delete"
        static let sync         = "Icons/UI/sync"
        static let budget       = "Icons/UI/budget"
        static let recurring    = "Icons/UI/recurring"
        static let categories   = "Icons/UI/categories"
        static let currency     = "Icons/UI/currency"
        static let export       = "Icons/UI/export"
        static let warningIcon  = "Icons/UI/warning"
        static let settle       = "Icons/UI/settle"
        static let profile      = "Icons/UI/profile"
        static let logout       = "Icons/UI/logout"
        static let check        = "Icons/UI/check"
        static let close        = "Icons/UI/close"
        static let more         = "Icons/UI/more"
    }

    // MARK: - Category icons
    enum Category {
        static let food          = "Icons/Category/food-dining"
        static let coffee        = "Icons/Category/coffee-cafe"
        static let groceries     = "Icons/Category/groceries"
        static let dining        = "Icons/Category/dining-out"
        static let transport     = "Icons/Category/transport"
        static let fuel          = "Icons/Category/fuel-petrol"
        static let transit       = "Icons/Category/public-transit"
        static let flights       = "Icons/Category/flights"
        static let housing       = "Icons/Category/housing-rent"
        static let health        = "Icons/Category/health-medical"
        static let pharmacy      = "Icons/Category/pharmacy"
        static let gym           = "Icons/Category/gym-fitness"
        static let yoga          = "Icons/Category/yoga-wellness"
        static let shopping      = "Icons/Category/shopping"
        static let clothing      = "Icons/Category/clothing"
        static let electronics   = "Icons/Category/electronics"
        static let entertainment = "Icons/Category/entertainment"
        static let music         = "Icons/Category/music"
        static let gaming        = "Icons/Category/gaming"
        static let books         = "Icons/Category/books-reading"
        static let travel        = "Icons/Category/travel"
        static let hotels        = "Icons/Category/hotels"
        static let subscriptions = "Icons/Category/subscriptions"
        static let streaming     = "Icons/Category/streaming"
        static let bills         = "Icons/Category/bills-utilities"
        static let phone         = "Icons/Category/phone-internet"
        static let electricity   = "Icons/Category/electricity-gas"
        static let insurance     = "Icons/Category/insurance"
        static let education     = "Icons/Category/education"
        static let courses       = "Icons/Category/online-courses"
        static let investments   = "Icons/Category/investments"
        static let salary        = "Icons/Category/salary-income"
        static let savings       = "Icons/Category/savings"
        static let personalCare  = "Icons/Category/personal-care"
        static let haircut       = "Icons/Category/haircut-salon"
        static let pets          = "Icons/Category/pets"
        static let gifts         = "Icons/Category/gifts"
        static let work          = "Icons/Category/work-office"
        static let freelance     = "Icons/Category/freelance"
        static let atm           = "Icons/Category/atm-cash"
        static let taxes         = "Icons/Category/taxes"
        static let donation      = "Icons/Category/donation-charity"
        static let baby          = "Icons/Category/baby-kids"
        static let misc          = "Icons/Category/miscellaneous"
    }

    // MARK: - Category tint colors (design-spec palette)
    enum CategoryColor {
        static let teal   = Color("CatTeal",   bundle: .main)
        static let red    = Color("CatRed",    bundle: .main)
        static let green  = Color("CatGreen",  bundle: .main)
        static let orange = Color("CatOrange", bundle: .main)
        static let purple = Color("CatPurple", bundle: .main)
        static let blue   = Color("CatBlue",   bundle: .main)
        static let pink   = Color("CatPink",   bundle: .main)
        static let indigo = Color("CatIndigo", bundle: .main)
        static let sky    = Color("CatSky",    bundle: .main)
        static let yellow = Color("CatYellow", bundle: .main)
        static let mint   = Color("CatMint",   bundle: .main)
        static let coral  = Color("CatCoral",  bundle: .main)
        static let brown  = Color("CatBrown",  bundle: .main)
        static let gray   = Color("CatGray",   bundle: .main)
        static let dark   = Color("CatDark",   bundle: .main)
        static let gold   = Color("CatGold",   bundle: .main)

        static let all: [Color] = [
            teal, red, green, orange, purple, blue,
            pink, indigo, sky, yellow, mint, coral,
            brown, gray, dark, gold
        ]
    }
}

// MARK: - SwiftUI rendering

/// Template image icon from Assets.xcassets/Icons/.
/// Tinted to the given color at runtime via template rendering mode.
struct AppIcon: View {
    let name: String
    var size: CGFloat = 24
    var color: Color = .primary

    var body: some View {
        Image(name, bundle: .main)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
            .frame(width: size, height: size)
    }
}
