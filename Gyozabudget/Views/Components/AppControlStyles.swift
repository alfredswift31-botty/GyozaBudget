import SwiftUI

struct AppPanelCardModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager

    let cornerRadius: CGFloat
    let emphasized: Bool

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.border.opacity(emphasized ? 1 : 0.9), lineWidth: emphasized ? 1.1 : 1)
            )
            .shadow(
                color: Color.black.opacity(
                    theme.option == .dark || theme.option == .zen
                        ? (emphasized ? 0.14 : 0.0)
                        : (emphasized ? 0.09 : 0.04)
                ),
                radius: theme.option == .dark || theme.option == .zen
                    ? (emphasized ? 10 : 0)
                    : (emphasized ? 16 : 8),
                x: 0,
                y: theme.option == .dark || theme.option == .zen
                    ? (emphasized ? 6 : 0)
                    : (emphasized ? 10 : 4)
            )
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    @EnvironmentObject private var themeManager: ThemeManager

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(theme.primaryButtonFill)
            .foregroundColor(theme.primaryButtonText)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: Color.black.opacity(theme.option == .dark ? 0.22 : 0.08),
                radius: configuration.isPressed ? 8 : 12,
                x: 0,
                y: configuration.isPressed ? 4 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.16), value: configuration.isPressed)
    }
}

extension View {
    func appPanelCard(cornerRadius: CGFloat = 24, emphasized: Bool = false) -> some View {
        modifier(AppPanelCardModifier(cornerRadius: cornerRadius, emphasized: emphasized))
    }

    /// Trailing swipe Delete that stays readable in every theme.
    /// App-wide `.tint(theme.accent)` is near-white in dark mode and was
    /// painting the default swipe chip as a blank white block. This forces
    /// a red plate + clear X icon so the action is obvious.
    func transactionDeleteSwipe(
        tint: Color = Color(red: 0.90, green: 0.24, blue: 0.26),
        action: @escaping () -> Void
    ) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: action) {
                Label {
                    Text("Delete")
                } icon: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .symbolRenderingMode(.monochrome)
                }
            }
            .tint(tint)
            .accessibilityLabel("Delete transaction")
        }
    }
}
