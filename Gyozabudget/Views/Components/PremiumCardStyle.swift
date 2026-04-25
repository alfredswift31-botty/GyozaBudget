import SwiftUI

struct PremiumCardModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    let cornerRadius: CGFloat
    let emphasis: Bool
    let glowEnabled: Bool

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                cardSurface(for: shape)
            }
    }

    @ViewBuilder
    private func cardSurface(for shape: RoundedRectangle) -> some View {
        switch theme.option {
        case .light:
            lightCardSurface(for: shape)
        case .dark:
            darkOrZenCardSurface(for: shape, accentStrength: 0.07)
        case .zen:
            darkOrZenCardSurface(for: shape, accentStrength: 0.10)
        }
    }

    private func lightCardSurface(for shape: RoundedRectangle) -> some View {
        shape
            .fill(theme.premiumCardFillGradient(emphasis: emphasis))
            .overlay {
                shape
                    .strokeBorder(
                        theme.premiumCardBorderGradient(emphasis: emphasis),
                        lineWidth: emphasis ? 1.1 : 0.9
                    )
            }
            .shadow(color: Color.black.opacity(emphasis ? 0.08 : 0.04), radius: emphasis ? 14 : 8, x: 0, y: emphasis ? 8 : 4)
    }

    private func darkOrZenCardSurface(
        for shape: RoundedRectangle,
        accentStrength: Double
    ) -> some View {
        shape
            .fill(theme.premiumCardFillGradient(emphasis: emphasis))
            .overlay {
                if emphasis {
                    shape
                        .fill(theme.accent.opacity(accentStrength))
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                shape
                    .strokeBorder(
                        theme.premiumCardBorderGradient(emphasis: emphasis),
                        lineWidth: emphasis ? 1.05 : 0.9
                    )
            }
            .shadow(
                color: Color.black.opacity(emphasis ? 0.18 : 0.0),
                radius: emphasis ? 12 : 0,
                x: 0,
                y: emphasis ? 7 : 0
            )
    }
}

extension View {
    func premiumCard(cornerRadius: CGFloat = 24, emphasis: Bool = false, glowEnabled: Bool = true) -> some View {
        modifier(PremiumCardModifier(cornerRadius: cornerRadius, emphasis: emphasis, glowEnabled: glowEnabled))
    }
}
