import Foundation

enum AppPreferences {
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    static let themePreferenceKey = "themePreference"
    static let currencyCodeKey = "currencyCode"
    static let defaultCurrencyCode = Locale.current.currency?.identifier ?? "USD"
    static let supportedCurrencyCodes = ["USD", "EUR", "GBP", "JPY", "AUD", "CAD", "MMK"]
}
