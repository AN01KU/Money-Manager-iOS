import SwiftUI

extension View {
    /// Dismisses the keyboard immediately when the user begins scrolling.
    func dismissKeyboardOnScroll() -> some View {
        self.scrollDismissesKeyboard(.immediately)
    }
}
