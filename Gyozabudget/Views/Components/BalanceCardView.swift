import SwiftUI

struct BalanceCardView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ScaledMetric(relativeTo: .largeTitle) private var balanceFontSize: CGFloat = 56
    let balance: Double
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Gyoza Balance")
                .font(.caption.weight(.semibold))
                .foregroundColor(theme.premiumCardTextSecondary)
                .textCase(.uppercase)
                .tracking(0.35)

            Text(balance, format: currencyStyle)
                .font(.system(size: balanceFontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(theme.premiumCardTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCard(cornerRadius: 28, emphasis: true)
    }
}
