//
//  OnboardingPage.swift
//  Money Manager
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
    var features: [String] = []
}
