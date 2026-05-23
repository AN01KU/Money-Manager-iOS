import SwiftUI

private struct TapFeedbackModifier: ViewModifier {
    let feedback: SensoryFeedback
    @State private var trigger = 0

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(TapGesture().onEnded { trigger += 1 })
            .sensoryFeedback(feedback, trigger: trigger)
    }
}

extension View {
    func tapFeedback(_ feedback: SensoryFeedback = .impact(weight: .light)) -> some View {
        modifier(TapFeedbackModifier(feedback: feedback))
    }
}
