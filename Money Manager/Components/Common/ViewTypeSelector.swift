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
                    HStack {
                        Text(viewType.rawValue)
                            .font(.body)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(selectedView == viewType ? .teal : .secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            Spacer()
        }
    }
}

#Preview {
    ViewTypeSelector(selectedView: .constant(.daily))
        .padding()
}
