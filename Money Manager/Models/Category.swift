//
//  Category.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

enum Category: String, CaseIterable, Identifiable {
    case food = "Food & Dining"
    case transport = "Transport"
    case utilities = "Utilities"
    case shopping = "Shopping"
    case housing = "Housing"
    case healthMedical = "Health & Medical"
    case entertainment = "Entertainment"
    case travel = "Travel"
    case workProfessional = "Work & Professional"
    case education = "Education"
    case debtPayments = "Debt & Payments"
    case booksMedia = "Books & Media"
    case familyKids = "Family & Kids"
    case gifts = "Gifts"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .food:
            return "fork.knife.circle.fill"
        case .transport:
            return "car.circle.fill"
        case .utilities:
            return "bolt.square.fill"
        case .shopping:
            return "bag.circle.fill"
        case .housing:
            return "house.circle.fill"
        case .healthMedical:
            return "cross.case.circle.fill"
        case .entertainment:
            return "gamecontroller.circle.fill"
        case .travel:
            return "airplane.circle.fill"
        case .workProfessional:
            return "briefcase.circle.fill"
        case .education:
            return "book.circle.fill"
        case .debtPayments:
            return "creditcard.circle.fill"
        case .booksMedia:
            return "book.closed.circle.fill"
        case .familyKids:
            return "figure.2.and.child.holdinghands"
        case .gifts:
            return "gift.circle.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .food:
            return Color(hex: "#FF6B6B")
        case .transport:
            return Color(hex: "#4ECDC4")
        case .utilities:
            return Color(hex: "#DDA15E")
        case .shopping:
            return Color(hex: "#FFEAA7")
        case .housing:
            return Color(hex: "#45B7D1")
        case .healthMedical:
            return Color(hex: "#96CEB4")
        case .entertainment:
            return Color(hex: "#BC6C25")
        case .travel:
            return Color(hex: "#8E44AD")
        case .workProfessional:
            return Color(hex: "#34495E")
        case .education:
            return Color(hex: "#3498DB")
        case .debtPayments:
            return Color(hex: "#2C3E50")
        case .booksMedia:
            return Color(hex: "#E74C3C")
        case .familyKids:
            return Color(hex: "#F39C12")
        case .gifts:
            return Color(hex: "#E91E63")
        case .other:
            return Color(hex: "#95A5A6")
        }
    }
    
    static func fromPredefined(_ predefined: PredefinedCategory) -> Category {
        switch predefined {
        case .foodDining:
            return .food
        case .transport:
            return .transport
        case .utilities:
            return .utilities
        case .shopping:
            return .shopping
        case .housing:
            return .housing
        case .healthMedical:
            return .healthMedical
        case .entertainment:
            return .entertainment
        case .travel:
            return .travel
        case .workProfessional:
            return .workProfessional
        case .education:
            return .education
        case .debtPayments:
            return .debtPayments
        case .booksMedia:
            return .booksMedia
        case .familyKids:
            return .familyKids
        case .gifts:
            return .gifts
        case .other:
            return .other
        }
    }
    
    static func fromString(_ categoryName: String) -> Category {
        if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == categoryName }) {
            return fromPredefined(predefined)
        }
        return .other
    }
}
