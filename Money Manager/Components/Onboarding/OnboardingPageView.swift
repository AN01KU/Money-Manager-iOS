import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            illustrationCard

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if !page.features.isEmpty {
                featureList
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Subviews

    private var illustrationCard: some View {
        ZStack {
            Circle()
                .fill(page.color.opacity(0.12))
                .frame(width: 180, height: 180)

            Circle()
                .fill(page.color.opacity(0.08))
                .frame(width: 220, height: 220)

            Image(systemName: page.icon)
                .font(.system(size: 72, weight: .medium))
                .foregroundStyle(page.color)
                .symbolEffect(.pulse, isActive: true)
        }
        .accessibilityHidden(true)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(page.features, id: \.self) { feature in
                FeatureBulletRow(text: feature, color: page.color)
            }
        }
        .padding(.horizontal, 40)
    }
}

private struct FeatureBulletRow: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(color)
                .font(.system(size: 16))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
    }
}
