import SwiftUI

extension Color {
    static func appBackground(for scheme: ColorScheme) -> Color {
        appBackground(for: ThemeManager.shared.currentTheme)
    }

    static func appBackground(for theme: AppTheme) -> Color {
        theme.background
    }

    static func appSurface(for scheme: ColorScheme) -> Color {
        appSurface(for: ThemeManager.shared.currentTheme)
    }

    static func appSurface(for theme: AppTheme) -> Color {
        theme.surface
    }

    static func appSurfaceAlt(for scheme: ColorScheme) -> Color {
        appSurfaceAlt(for: ThemeManager.shared.currentTheme)
    }

    static func appSurfaceAlt(for theme: AppTheme) -> Color {
        theme.card
    }

    static func appBorder(for scheme: ColorScheme) -> Color {
        appBorder(for: ThemeManager.shared.currentTheme)
    }

    static func appBorder(for theme: AppTheme) -> Color {
        theme.border
    }

    static func appDivider(for scheme: ColorScheme) -> Color {
        appDivider(for: ThemeManager.shared.currentTheme)
    }

    static func appDivider(for theme: AppTheme) -> Color {
        theme.divider
    }

    static func appPrimaryText(for scheme: ColorScheme) -> Color {
        appPrimaryText(for: ThemeManager.shared.currentTheme)
    }

    static func appPrimaryText(for theme: AppTheme) -> Color {
        theme.primaryText
    }

    static func appSecondaryText(for scheme: ColorScheme) -> Color {
        appSecondaryText(for: ThemeManager.shared.currentTheme)
    }

    static func appSecondaryText(for theme: AppTheme) -> Color {
        theme.secondaryText
    }

    static func appAccentSurface(for scheme: ColorScheme) -> Color {
        appAccentSurface(for: ThemeManager.shared.currentTheme)
    }

    static func appAccentSurface(for theme: AppTheme) -> Color {
        theme.subtleAccent
    }

    static func appAccent(for scheme: ColorScheme) -> Color {
        appAccent(for: ThemeManager.shared.currentTheme)
    }

    static func appAccent(for theme: AppTheme) -> Color {
        theme.accent
    }

    static func appProgressBackground(for scheme: ColorScheme) -> Color {
        appProgressBackground(for: ThemeManager.shared.currentTheme)
    }

    static func appProgressBackground(for theme: AppTheme) -> Color {
        theme.progressBackground
    }

    static func appProgressFill(for scheme: ColorScheme, isPrimary: Bool = true) -> Color {
        appProgressFill(for: ThemeManager.shared.currentTheme, isPrimary: isPrimary)
    }

    static func appProgressFill(for theme: AppTheme, isPrimary: Bool = true) -> Color {
        isPrimary ? theme.accent : theme.secondary.opacity(theme.option == .dark ? 0.55 : 0.5)
    }
}
