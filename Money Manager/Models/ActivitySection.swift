//
//  ActivitySection.swift
//  Money Manager
//

import Foundation

struct ActivitySection: Identifiable {
    let id: String
    let label: String
    let items: [ActivityItem]
}
