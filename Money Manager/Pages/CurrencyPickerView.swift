//
//  CurrencyPickerView.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 15/02/26.
//

import SwiftUI

struct CurrencyPickerView: View {
    @Environment(\.authService) private var authService
    @AppStorage("selectedCurrency") private var selectedCurrency = "INR"
    @State private var searchText = ""
    @State private var selectionToggled = 0
    @State private var isUpdating = false
    @State private var showError = false
    @State private var errorMessage = ""

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
                    guard !isUpdating, currency.code != selectedCurrency else { return }
                    selectionToggled += 1
                    Task { await select(currency.code) }
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
                            if isUpdating {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.accent)
                            }
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: selectionToggled)
            }
        }
        .searchable(text: $searchText, prompt: "Search currencies")
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func select(_ code: String) async {
        let previous = selectedCurrency
        selectedCurrency = code
        isUpdating = true
        do {
            try await authService.updateCurrency(code)
        } catch {
            selectedCurrency = previous
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
        isUpdating = false
    }
}

#Preview {
    NavigationStack {
        CurrencyPickerView()
    }
}
