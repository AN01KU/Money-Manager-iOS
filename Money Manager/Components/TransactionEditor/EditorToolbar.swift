import SwiftUI

struct EditorToolbar: ToolbarContent {
    let isSaving: Bool
    let isValid: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel", action: onCancel)
                .accessibilityIdentifier("cancel-button")
        }
        ToolbarItem(placement: .topBarTrailing) {
            if isSaving {
                ProgressView()
            } else {
                Button("Save", action: onSave)
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                    .accessibilityIdentifier("save-button")
            }
        }
    }
}
