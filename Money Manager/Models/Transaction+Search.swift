import Foundation

extension Transaction {
    /// Returns true if the transaction matches the given search text.
    /// Category name matching requires a pre-built lookup passed in.
    func matches(searchText: String, categoryName: String = "") -> Bool {
        guard !searchText.isEmpty else { return true }
        return categoryName.localizedStandardContains(searchText) ||
            (transactionDescription?.localizedStandardContains(searchText) ?? false) ||
            (notes?.localizedStandardContains(searchText) ?? false)
    }
}
