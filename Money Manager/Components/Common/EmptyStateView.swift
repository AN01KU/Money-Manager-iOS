//
//  EmptyStateView.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    @State private var buttonTapped = 0
    
    init(
        icon: String = "tray",
        title: String = "Nothing here yet",
        message: String = "Items you add will appear here",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    buttonTapped += 1
                    action()
                }) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: buttonTapped)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title). \(message)")
    }
}

#Preview {
    EmptyStateView()
        .padding()
}
