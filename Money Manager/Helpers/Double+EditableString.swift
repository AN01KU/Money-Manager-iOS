import Foundation

extension Double {
    /// Formats a Double for use in an editable text field — no locale grouping separators,
    /// no trailing decimal if the value is whole (e.g. 1000 → "1000", 9.99 → "9.99").
    var editableString: String {
        String(format: truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f", self)
    }
}
