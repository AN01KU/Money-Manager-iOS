//
//  CurrencyPickerView.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 15/02/26.
//

import SwiftUI

struct CurrencyPickerView: View {
    @AppStorage("selectedCurrency") private var selectedCurrency = "INR"
    @State private var searchText = ""
    @State private var selectionToggled = false
    
    private var filteredCurrencies: [(code: String, name: String, symbol: String)] {
        if searchText.isEmpty {
            return CurrencyFormatter.supportedCurrencies
        }
        let query = searchText.lowercased()
        return CurrencyFormatter.supportedCurrencies.filter {
            $0.code.lowercased().contains(query) ||
            $0.name.lowercased().contains(query) ||
            $0.symbol.contains(query)
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredCurrencies, id: \.code) { currency in
                Button {
                    selectionToggled = true
                    selectedCurrency = currency.code
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(AppColors.accentSubtle)
                                .frame(width: 40, height: 40)

                            Text(currency.symbol)
                                .font(.headline)
                                .foregroundStyle(AppColors.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.name)
                                .font(.body)
                                .foregroundStyle(.primary)

                            Text(currency.code)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedCurrency == currency.code {
                            Image(systemName: "checkmark")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: selectionToggled)
                .onChange(of: selectionToggled) { _, newValue in
                    if newValue { selectionToggled = false }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search currencies")
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CurrencyPickerView()
    }
}
