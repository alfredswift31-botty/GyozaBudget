import SwiftUI
import Combine

enum ThemeOption: String, Identifiable, CaseIterable {
    case light
    case dark
    case zen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .zen:
            return "Zen"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light, .zen:
            return .light
        case .dark:
            return .dark
        }
    }

    var theme: AppTheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .zen:
            return .zen
        }
    }
}

struct AppTheme {
    let option: ThemeOption
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let subtleAccent: Color
    let cardBackground: Color
    let colorScheme: ColorScheme

    var card: Color { cardBackground }

    static let light = AppTheme(
        option: .light,
        background: Color(hex: "#F7F7F5"),
        surface: Color(hex: "#EFEFEA"),
        primary: Color(hex: "#1E231F"),
        secondary: Color(hex: "#6A6D69"),
        textPrimary: Color(hex: "#1E231F"),
        textSecondary: Color(hex: "#6A6D69"),
        accent: Color(hex: "#1E231F"),
        subtleAccent: Color(hex: "#E5E5DF"),
        cardBackground: Color(hex: "#FFFFFF"),
        colorScheme: .light
    )

    static let dark = AppTheme(
        option: .dark,
        background: Color(hex: "#111214"),
        surface: Color(hex: "#202227"),
        primary: Color(hex: "#F3F4F6"),
        secondary: Color(hex: "#AEB3BA"),
        textPrimary: Color(hex: "#F3F4F6"),
        textSecondary: Color(hex: "#AEB3BA"),
        accent: Color(hex: "#F3F4F6"),
        subtleAccent: Color(hex: "#2C2F35"),
        cardBackground: Color(hex: "#1A1C20"),
        colorScheme: .dark
    )

    static let zen = AppTheme(
        option: .zen,
        background: Color(hex: "#DEDCD2"),
        surface: Color(hex: "#B4BEA5"),
        primary: Color(hex: "#62815F"),
        secondary: Color(hex: "#48644E"),
        textPrimary: Color(hex: "#304238"),
        textSecondary: Color(hex: "#526755"),
        accent: Color(hex: "#62815F"),
        subtleAccent: Color(hex: "#D1D7C5"),
        cardBackground: Color(hex: "#C7CFBB"),
        colorScheme: .light
    )

    var border: Color {
        textPrimary.opacity(colorScheme == .dark ? 0.14 : 0.10)
    }

    var divider: Color {
        textPrimary.opacity(colorScheme == .dark ? 0.10 : 0.08)
    }

    var progressBackground: Color {
        option == .dark ? subtleAccent.opacity(0.92) : subtleAccent
    }

    var premiumCardTop: Color {
        switch option {
        case .light:
            return Color(hex: "#FFFFFF")
        case .dark:
            return Color(hex: "#24272D")
        case .zen:
            return Color(hex: "#31463A")
        }
    }

    var premiumCardTextPrimary: Color {
        switch option {
        case .light:
            return textPrimary
        case .dark:
            return Color(hex: "#F4F5F7")
        case .zen:
            return Color(hex: "#F1F4EB")
        }
    }

    var premiumCardTextSecondary: Color {
        switch option {
        case .light:
            return textSecondary
        case .dark:
            return Color(hex: "#B7BDC6")
        case .zen:
            return Color(hex: "#C2CCBA")
        }
    }

    var primaryButtonFill: Color {
        switch option {
        case .light, .dark:
            return accent
        case .zen:
            return secondary
        }
    }

    var primaryButtonText: Color {
        switch option {
        case .light, .zen:
            return Color.white
        case .dark:
            return background
        }
    }

    /// Fixed red for swipe-delete and other destructive actions.
    /// Must NOT use `accent` — dark theme accent is near-white, which made
    /// swipe Delete chips look like blank white blocks.
    var destructive: Color {
        Color(red: 0.90, green: 0.24, blue: 0.26)
    }

}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var themeOption: ThemeOption
    @Published private(set) var currentTheme: AppTheme

    private init() {
        let storedPreference = UserDefaults.standard.string(forKey: AppPreferences.themePreferenceKey)
        let option = ThemeOption(rawValue: storedPreference ?? ThemeOption.light.rawValue) ?? .light
        self.themeOption = option
        self.currentTheme = option.theme
    }

    func applyPreference(_ rawValue: String) {
        let option = ThemeOption(rawValue: rawValue) ?? .light
        themeOption = option
        currentTheme = option.theme
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}
