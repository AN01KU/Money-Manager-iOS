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
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Color.gray.opacity(0.1)
        FloatingActionButton(icon: "plus", action: {})
            .padding()
    }
}
