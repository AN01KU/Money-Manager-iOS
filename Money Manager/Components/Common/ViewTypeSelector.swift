//
//  ViewTypeSelector.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

enum ViewType: String, CaseIterable {
    case daily = "Daily"
    case categories = "Categories"
}

struct ViewTypeSelector: View {
    @Binding var selectedView: ViewType
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(ViewType.allCases, id: \.self) { viewType in
                Button(action: {
                    selectedView = viewType
                }) {
                    Text(viewType.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(selectedView == viewType ? .teal : .secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(selectedView == viewType ? Color.teal.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(12)
                }
                .buttonStyle(.borderless)
            }
            Spacer()
        }
    }
}

#Preview {
    ViewTypeSelector(selectedView: .constant(.daily))
        .padding()
}
