//
//  FloatingActionButton.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var color: Color = .teal
    @State private var tapped = false
    
    var body: some View {
        Button(action: {
            tapped = true
            action()
        }) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: tapped)
        .onChange(of: tapped) { _, newValue in
            if newValue { tapped = false }
        }
        .accessibilityLabel("Add new transaction")
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        AppColors.grayLight
        FloatingActionButton(icon: "plus", action: {})
            .padding()
    }
}
