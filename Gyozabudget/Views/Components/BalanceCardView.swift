import SwiftUI

struct BalanceCardView: View {
    @EnvironmentObject private var themeManager: ThemeManager
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
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(theme.premiumCardTextPrimary)
                .lineLimit(1)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCard(cornerRadius: 28, emphasis: true)
    }
}
