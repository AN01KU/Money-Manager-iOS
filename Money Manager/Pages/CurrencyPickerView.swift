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
        ScrollView {
            VStack(spacing: 0) {
                ForEach(filteredCurrencies, id: \.code) { currency in
                    Button {
                        guard !isUpdating, currency.code != selectedCurrency else { return }
                        selectionToggled += 1
                        Task { await select(currency.code) }
                    } label: {
                        HStack(spacing: AppConstants.UI.spacing12) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.accentLight)
                                    .frame(width: AppConstants.UI.iconBadgeSize, height: AppConstants.UI.iconBadgeSize)
                                Text(currency.symbol)
                                    .font(AppTypography.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.accent)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(currency.name)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.accent)
                                Text(currency.code)
                                    .font(AppTypography.caption1)
                                    .foregroundStyle(AppColors.label2)
                            }

                            Spacer()

                            if selectedCurrency == currency.code {
                                if isUpdating {
                                    ProgressView().controlSize(.small).tint(AppColors.accent)
                                } else {
                                    AppIcon(name: AppIcons.UI.check, size: 18, color: AppColors.accent)
                                }
                            }
                        }
                        .padding(.horizontal, AppConstants.UI.padding)
                        .padding(.vertical, AppConstants.UI.spacing12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: selectionToggled)

                    if currency.code != filteredCurrencies.last?.code {
                        Divider().padding(.leading, AppConstants.UI.iconBadgeSize + AppConstants.UI.padding + AppConstants.UI.spacing12)
                    }
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
            .padding(AppConstants.UI.padding)
        }
        .background(AppColors.background)
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
