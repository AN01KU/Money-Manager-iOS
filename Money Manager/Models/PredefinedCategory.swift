import SwiftUI

enum PredefinedCategory: String, CaseIterable, Identifiable {
    // Food & Drink
    case foodDining      = "Food & Dining"
    case coffeeCafe      = "Coffee & Café"
    case groceries       = "Groceries"
    case diningOut       = "Dining Out"
    // Transport
    case transport       = "Transport"
    case fuelPetrol      = "Fuel & Petrol"
    case publicTransit   = "Public Transit"
    case flights         = "Flights"
    // Home
    case housingRent     = "Housing & Rent"
    // Health
    case healthMedical   = "Health & Medical"
    case pharmacy        = "Pharmacy"
    case gymFitness      = "Gym & Fitness"
    case yogaWellness    = "Yoga & Wellness"
    // Shopping
    case shopping        = "Shopping"
    case clothing        = "Clothing"
    case electronics     = "Electronics"
    // Entertainment
    case entertainment   = "Entertainment"
    case music           = "Music"
    case gaming          = "Gaming"
    case booksReading    = "Books & Reading"
    // Travel
    case travel          = "Travel"
    case hotels          = "Hotels"
    // Subscriptions & Bills
    case subscriptions   = "Subscriptions"
    case streaming       = "Streaming"
    case billsUtilities  = "Bills & Utilities"
    case phoneInternet   = "Phone & Internet"
    case electricityGas  = "Electricity & Gas"
    case insurance       = "Insurance"
    // Education
    case education       = "Education"
    case onlineCourses   = "Online Courses"
    // Finance
    case investments     = "Investments"
    case salaryIncome    = "Salary & Income"
    case savings         = "Savings"
    // Personal
    case personalCare    = "Personal Care"
    case haircutSalon    = "Haircut & Salon"
    case pets            = "Pets"
    case gifts           = "Gifts"
    // Work
    case workOffice      = "Work & Office"
    case freelance       = "Freelance"
    // Misc
    case atmCash         = "ATM & Cash"
    case taxes           = "Taxes"
    case donationCharity = "Donation & Charity"
    case babyKids        = "Baby & Kids"
    case other           = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .foodDining:      return AppIcons.Category.food
        case .coffeeCafe:      return AppIcons.Category.coffee
        case .groceries:       return AppIcons.Category.groceries
        case .diningOut:       return AppIcons.Category.dining
        case .transport:       return AppIcons.Category.transport
        case .fuelPetrol:      return AppIcons.Category.fuel
        case .publicTransit:   return AppIcons.Category.transit
        case .flights:         return AppIcons.Category.flights
        case .housingRent:     return AppIcons.Category.housing
        case .healthMedical:   return AppIcons.Category.health
        case .pharmacy:        return AppIcons.Category.pharmacy
        case .gymFitness:      return AppIcons.Category.gym
        case .yogaWellness:    return AppIcons.Category.yoga
        case .shopping:        return AppIcons.Category.shopping
        case .clothing:        return AppIcons.Category.clothing
        case .electronics:     return AppIcons.Category.electronics
        case .entertainment:   return AppIcons.Category.entertainment
        case .music:           return AppIcons.Category.music
        case .gaming:          return AppIcons.Category.gaming
        case .booksReading:    return AppIcons.Category.books
        case .travel:          return AppIcons.Category.travel
        case .hotels:          return AppIcons.Category.hotels
        case .subscriptions:   return AppIcons.Category.subscriptions
        case .streaming:       return AppIcons.Category.streaming
        case .billsUtilities:  return AppIcons.Category.bills
        case .phoneInternet:   return AppIcons.Category.phone
        case .electricityGas:  return AppIcons.Category.electricity
        case .insurance:       return AppIcons.Category.insurance
        case .education:       return AppIcons.Category.education
        case .onlineCourses:   return AppIcons.Category.courses
        case .investments:     return AppIcons.Category.investments
        case .salaryIncome:    return AppIcons.Category.salary
        case .savings:         return AppIcons.Category.savings
        case .personalCare:    return AppIcons.Category.personalCare
        case .haircutSalon:    return AppIcons.Category.haircut
        case .pets:            return AppIcons.Category.pets
        case .gifts:           return AppIcons.Category.gifts
        case .workOffice:      return AppIcons.Category.work
        case .freelance:       return AppIcons.Category.freelance
        case .atmCash:         return AppIcons.Category.atm
        case .taxes:           return AppIcons.Category.taxes
        case .donationCharity: return AppIcons.Category.donation
        case .babyKids:        return AppIcons.Category.baby
        case .other:           return AppIcons.Category.other
        }
    }

    /// Palette hex for this category, sourced from `AppIcons.CategoryColor.palette`.
    var paletteHex: String {
        switch self {
        case .foodDining:      return "#16C5CC"
        case .coffeeCafe:      return "#A1845E"
        case .groceries:       return "#34C658"
        case .diningOut:       return "#FF9400"
        case .transport:       return "#0079FF"
        case .fuelPetrol:      return "#FF9400"
        case .publicTransit:   return "#5AC7F9"
        case .flights:         return "#5755D5"
        case .housingRent:     return "#5AC7F9"
        case .healthMedical:   return "#FF3A2F"
        case .pharmacy:        return "#FF3A2F"
        case .gymFitness:      return "#34C658"
        case .yogaWellness:    return "#BE5AF1"
        case .shopping:        return "#FF2C54"
        case .clothing:        return "#FF2C54"
        case .electronics:     return "#5755D5"
        case .entertainment:   return "#FF9400"
        case .music:           return "#BE5AF1"
        case .gaming:          return "#5755D5"
        case .booksReading:    return "#A1845E"
        case .travel:          return "#16C5CC"
        case .hotels:          return "#5AC7F9"
        case .subscriptions:   return "#FF9400"
        case .streaming:       return "#FF3A2F"
        case .billsUtilities:  return "#8E8E92"
        case .phoneInternet:   return "#0079FF"
        case .electricityGas:  return "#FFD509"
        case .insurance:       return "#34C658"
        case .education:       return "#0079FF"
        case .onlineCourses:   return "#5755D5"
        case .investments:     return "#34C658"
        case .salaryIncome:    return "#34C658"
        case .savings:         return "#00C6BD"
        case .personalCare:    return "#FF2C54"
        case .haircutSalon:    return "#FF2C54"
        case .pets:            return "#A1845E"
        case .gifts:           return "#FF2C54"
        case .workOffice:      return "#39393B"
        case .freelance:       return "#16C5CC"
        case .atmCash:         return "#8E8E92"
        case .taxes:           return "#39393B"
        case .donationCharity: return "#FF3A2F"
        case .babyKids:        return "#FF9400"
        case .other:           return "#8E8E92"
        }
    }

    /// The kebab-case server key (e.g. "food-dining"). Used everywhere as the
    /// stable identifier for a predefined category — in API payloads, in
    /// `Category.predefinedKey`, and in `TransactionCategory.id`.
    nonisolated var serverKey: String {
        switch self {
        case .foodDining:      return "food-dining"
        case .coffeeCafe:      return "coffee-cafe"
        case .groceries:       return "groceries"
        case .diningOut:       return "dining-out"
        case .transport:       return "transport"
        case .fuelPetrol:      return "fuel-petrol"
        case .publicTransit:   return "public-transit"
        case .flights:         return "flights"
        case .housingRent:     return "housing-rent"
        case .healthMedical:   return "health-medical"
        case .pharmacy:        return "pharmacy"
        case .gymFitness:      return "gym-fitness"
        case .yogaWellness:    return "yoga-wellness"
        case .shopping:        return "shopping"
        case .clothing:        return "clothing"
        case .electronics:     return "electronics"
        case .entertainment:   return "entertainment"
        case .music:           return "music"
        case .gaming:          return "gaming"
        case .booksReading:    return "books-reading"
        case .travel:          return "travel"
        case .hotels:          return "hotels"
        case .subscriptions:   return "subscriptions"
        case .streaming:       return "streaming"
        case .billsUtilities:  return "bills-utilities"
        case .phoneInternet:   return "phone-internet"
        case .electricityGas:  return "electricity-gas"
        case .insurance:       return "insurance"
        case .education:       return "education"
        case .onlineCourses:   return "online-courses"
        case .investments:     return "investments"
        case .salaryIncome:    return "salary-income"
        case .savings:         return "savings"
        case .personalCare:    return "personal-care"
        case .haircutSalon:    return "haircut-salon"
        case .pets:            return "pets"
        case .gifts:           return "gifts"
        case .workOffice:      return "work-office"
        case .freelance:       return "freelance"
        case .atmCash:         return "atm-cash"
        case .taxes:           return "taxes"
        case .donationCharity: return "donation-charity"
        case .babyKids:        return "baby-kids"
        case .other:           return "other"
        }
    }

    /// Translates a stored `predefinedKey` value (which may be a legacy
    /// camelCase enum case name like `"foodDining"`, or the canonical kebab-case
    /// `serverKey` like `"food-dining"`) into the canonical `serverKey` form.
    /// Returns `nil` when the input matches no known case.
    nonisolated static func normalizeKey(_ raw: String) -> String? {
        if allCases.contains(where: { $0.serverKey == raw }) { return raw }
        return allCases.first { String(describing: $0) == raw }?.serverKey
    }
}

