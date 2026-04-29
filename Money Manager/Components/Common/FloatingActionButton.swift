//
//  FloatingActionButton.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct FloatingActionButton: View {
    var icon: String = AppIcons.UI.add
    let action: () -> Void
    var color: Color = AppColors.accent
    @State private var tapped = 0

    var body: some View {
        Button(action: {
            tapped += 1
            action()
        }) {
            AppIcon(name: icon, size: 24, color: .white)
                .frame(width: 60, height: 60)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: tapped)
        .accessibilityLabel("Add")
        .accessibilityIdentifier("fab-add")
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        AppColors.grayLight
        FloatingActionButton(action: {})
            .padding()
    }
}
