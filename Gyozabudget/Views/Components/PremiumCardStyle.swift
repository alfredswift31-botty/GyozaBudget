import SwiftUI

struct PremiumCardModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    let cornerRadius: CGFloat
    let emphasis: Bool

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background(shape.fill(theme.premiumCardTop))
            .overlay {
                if emphasis {
                    shape.strokeBorder(theme.accent.opacity(0.4), lineWidth: 1)
                }
            }
    }
}

extension View {
    // glowEnabled is accepted but unused so existing call sites compile unchanged.
    func premiumCard(cornerRadius: CGFloat = 16, emphasis: Bool = false, glowEnabled: Bool = true) -> some View {
        modifier(PremiumCardModifier(cornerRadius: cornerRadius, emphasis: emphasis))
    }
}
