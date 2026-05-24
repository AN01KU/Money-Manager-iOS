//
//  Transaction+Search.swift
//  Money Manager
//

import Foundation

extension Transaction {
    /// Returns true if the transaction matches the given search text.
    /// An empty search text always returns true.
    func matches(searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }
        return category.localizedStandardContains(searchText) ||
            (transactionDescription?.localizedStandardContains(searchText) ?? false) ||
            (notes?.localizedStandardContains(searchText) ?? false)
    }
}
