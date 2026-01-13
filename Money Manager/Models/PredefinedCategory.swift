//
//  PredefinedCategory.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

enum PredefinedCategory: String, CaseIterable, Identifiable {
    case foodDining = "Food & Dining"
    case transport = "Transport"
    case housing = "Housing"
    case healthMedical = "Health & Medical"
    case shopping = "Shopping"
    case utilities = "Utilities"
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
        case .foodDining:
            return "fork.knife.circle.fill"
        case .transport:
            return "car.circle.fill"
        case .housing:
            return "house.circle.fill"
        case .healthMedical:
            return "cross.case.circle.fill"
        case .shopping:
            return "bag.circle.fill"
        case .utilities:
            return "bolt.square.fill"
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
        case .foodDining:
            return Color(hex: "#FF6B6B")
        case .transport:
            return Color(hex: "#4ECDC4")
        case .housing:
            return Color(hex: "#45B7D1")
        case .healthMedical:
            return Color(hex: "#96CEB4")
        case .shopping:
            return Color(hex: "#FFEAA7")
        case .utilities:
            return Color(hex: "#DDA15E")
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
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
