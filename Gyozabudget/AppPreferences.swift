import Foundation

enum AppPreferences {
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    static let themePreferenceKey = "themePreference"
    static let currencyCodeKey = "currencyCode"
    static let supportedCurrencyCodes = ["USD", "EUR", "GBP", "JPY", "AUD", "CAD", "MMK"]
    /// Clamped to the supported list so Settings/Onboarding menus never show
    /// a currency the user can't re-select.
    static let defaultCurrencyCode: String = {
        let code = Locale.current.currency?.identifier ?? "USD"
        return supportedCurrencyCodes.contains(code) ? code : "USD"
    }()
    static let lastQuickAddCategoryKey = "lastQuickAddCategory"
    static let rememberLastQuickAddCategoryKey = "rememberLastQuickAddCategory"
    static let quickAddHapticsEnabledKey = "quickAddHapticsEnabled"

    /// Parses user-typed amounts locale-aware: "1,000" is a thousand in
    /// en_US, "1,5" is one-and-a-half in de_DE. NumberFormatter with the
    /// current locale handles grouping vs decimal separators; plain Double
    /// parsing is the fallback for inputs the formatter rejects.
    // ponytail: money stored as Double; migrate to Decimal/integer-cents if precision issues surface
    static func parseAmount(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal

        let value: Double?
        if let number = formatter.number(from: trimmed) {
            value = number.doubleValue
        } else {
            // Strip grouping separators, then try plain Double ("1234.56").
            let stripped = trimmed.replacingOccurrences(
                of: formatter.groupingSeparator ?? ",", with: ""
            )
            value = Double(stripped)
        }

        guard let value, value.isFinite, value >= 0 else { return nil }
        return value
    }

    /// Symbol shown next to bare amount fields, derived from the same
    /// FormatStyle used to render amounts so the two can never disagree.
    static func currencySymbol(for code: String) -> String {
        let sample = (0.0).formatted(.currency(code: code))
        let removalSet = CharacterSet(charactersIn: "0123456789.,-")
            .union(.whitespacesAndNewlines)
        let scalars = sample.unicodeScalars.filter { !removalSet.contains($0) }
        let symbol = String(String.UnicodeScalarView(scalars))
        return symbol.isEmpty ? code : symbol
    }
}
