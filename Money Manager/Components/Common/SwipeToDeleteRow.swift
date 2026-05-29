import SwiftUI

struct SwipeAction {
    let icon: String
    let color: Color
    let action: () -> Void
}

struct SwipeToDeleteRow<Content: View>: View {
    @Binding var isRevealed: Bool
    let onDelete: () -> Void
    var deleteIcon: String = "trash.fill"
    var deleteColor: Color = AppColors.expense
    var secondaryAction: SwipeAction? = nil
    var onTap: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    private let buttonWidth: CGFloat = 80
    private var totalWidth: CGFloat { secondaryAction != nil ? buttonWidth * 2 : buttonWidth }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                if let secondary = secondaryAction {
                    Button {
                        secondary.action()
                        resetSwipe()
                    } label: {
                        Image(systemName: secondary.icon)
                            .font(AppTypography.destructiveIcon)
                            .foregroundStyle(.white)
                            .frame(width: buttonWidth)
                            .frame(maxHeight: .infinity)
                    }
                    .background(secondary.color)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    onDelete()
                    resetSwipe()
                } label: {
                    Image(systemName: deleteIcon)
                        .font(AppTypography.destructiveIcon)
                        .foregroundStyle(.white)
                        .frame(width: buttonWidth)
                        .frame(maxHeight: .infinity)
                }
                .background(deleteColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .opacity(offset < 0 ? 1 : 0)

            content()
                .offset(x: offset)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            let translation = value.translation.width
                            if isRevealed {
                                offset = min(0, -totalWidth + translation)
                            } else if translation < 0 {
                                offset = max(-totalWidth, translation)
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
        withAnimation(.easeOut(duration: 0.2)) { offset = -totalWidth }
        isRevealed = true
    }

    private func resetSwipe() {
        withAnimation(.easeOut(duration: 0.2)) { offset = 0 }
        isRevealed = false
    }
}
