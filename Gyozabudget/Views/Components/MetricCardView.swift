import SwiftUI

struct MetricCardView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    let value: Double
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency
    let labelColor: Color

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundColor(labelColor)
                .textCase(.uppercase)
                .tracking(0.35)
            Text(value, format: currencyStyle)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundColor(theme.premiumCardTextPrimary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCard(cornerRadius: 22)
    }
}
