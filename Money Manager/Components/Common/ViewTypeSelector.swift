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
    @State private var selectionChanged = false
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(ViewType.allCases, id: \.self) { viewType in
                Button(action: {
                    selectionChanged = true
                    selectedView = viewType
                }) {
                    Text(viewType.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(selectedView == viewType ? AppColors.accent : .secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(selectedView == viewType ? AppColors.accentLight : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.borderless)
                .sensoryFeedback(.selection, trigger: selectionChanged)
                .onChange(of: selectionChanged) { _, newValue in
                    if newValue { selectionChanged = false }
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
