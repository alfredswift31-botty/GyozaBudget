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
            .background(theme.accent)
            .foregroundColor(theme.premiumOnAccent)
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

struct AppSwitchToggleStyle: ToggleStyle {
    @EnvironmentObject private var themeManager: ThemeManager

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                configuration.isOn.toggle()
            }
        } label: {
            HStack(spacing: 14) {
                configuration.label
                Spacer(minLength: 12)
                toggleTrack(isOn: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggleTrack(isOn: Bool) -> some View {
        let thumbColor: Color = {
            if isOn && theme.option == .dark {
                return theme.background
            }
            return Color.white
        }()

        let trackColor: Color = {
            if isOn {
                return theme.accent
            }
            return theme.option == .dark ? Color(hex: "#3A3F47") : theme.subtleAccent
        }()

        let borderColor: Color = {
            if isOn {
                return theme.option == .dark ? Color.white.opacity(0.16) : theme.accent.opacity(0.18)
            }
            return theme.option == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06)
        }()

        return ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(trackColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )

            Circle()
                .fill(thumbColor)
                .frame(width: 24, height: 24)
                .shadow(color: Color.black.opacity(theme.option == .dark ? 0.30 : 0.14), radius: 4, x: 0, y: 2)
                .padding(4)
        }
        .frame(width: 52, height: 34)
    }
}

extension View {
    func appPanelCard(cornerRadius: CGFloat = 24, emphasized: Bool = false) -> some View {
        modifier(AppPanelCardModifier(cornerRadius: cornerRadius, emphasized: emphasized))
    }
}
