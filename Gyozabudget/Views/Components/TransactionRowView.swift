import SwiftUI

struct TransactionRowView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let transaction: Transaction
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(transaction.category.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.premiumCardTextPrimary)
                Text(transaction.note ?? transaction.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundColor(theme.premiumCardTextSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(transaction.amount, format: currencyStyle)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(theme.premiumCardTextPrimary)
                Text(transaction.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption2)
                    .foregroundColor(theme.premiumCardTextSecondary)
            }
        }
        .padding(20)
        .premiumCard(cornerRadius: 22, glowEnabled: false)
    }
}
