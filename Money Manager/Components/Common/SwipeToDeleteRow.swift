import SwiftUI

struct SwipeToDeleteRow<Content: View>: View {
    @Binding var isRevealed: Bool
    let onDelete: () -> Void
    var onTap: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    private let buttonWidth: CGFloat = 80

    var body: some View {
        ZStack(alignment: .trailing) {
            Button {
                onDelete()
                resetSwipe()
            } label: {
                Image(systemName: "trash.fill")
                    .font(AppTypography.destructiveIcon)
                    .foregroundStyle(.white)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
            }
            .background(AppColors.expense)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(offset < 0 ? 1 : 0)

            content()
                .offset(x: offset)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            let translation = value.translation.width
                            if isRevealed {
                                offset = min(0, -buttonWidth + translation)
                            } else if translation < 0 {
                                offset = max(-buttonWidth, translation)
                            }
                        }
                        .onEnded { value in
                            if offset < -40 { revealButton() } else { resetSwipe() }
                        }
                )
                .simultaneousGesture(
                    TapGesture().onEnded {
                        if isRevealed {
                            resetSwipe()
                        } else {
                            onTap?()
                        }
                    }
                )
        }
        .onChange(of: isRevealed) { _, newValue in
            if !newValue && offset != 0 {
                withAnimation(.easeOut(duration: 0.2)) { offset = 0 }
            }
        }
        .accessibilityAction(named: "Delete") {
            onDelete()
        }
    }

    private func revealButton() {
        withAnimation(.easeOut(duration: 0.2)) { offset = -buttonWidth }
        isRevealed = true
    }

    private func resetSwipe() {
        withAnimation(.easeOut(duration: 0.2)) { offset = 0 }
        isRevealed = false
    }
}
