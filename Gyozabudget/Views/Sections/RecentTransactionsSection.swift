import SwiftUI

struct RecentTransactionsSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let transactions: [Transaction]
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency
    let emptyStateText: String
    let deleteAction: (Transaction) -> Void
    let onTapTransaction: (Transaction) -> Void
    let onViewAll: (() -> Void)?
    let onPrimaryAction: (() -> Void)?

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(theme.premiumCardTextPrimary)
                Spacer()
                if let onViewAll {
                    Button(action: onViewAll) {
                        Text("View All")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                } else {
                        Text("Latest")
                            .font(.caption)
                            .foregroundColor(theme.premiumCardTextSecondary)
                }
            }

            if transactions.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text(emptyStateText)
                        .font(.subheadline)
                        .foregroundColor(theme.premiumCardTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let onPrimaryAction {
                        Button(action: onPrimaryAction) {
                            Text("Add Transaction")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(AppPrimaryButtonStyle())
                    }
                }
                    .padding(20)
                    .premiumCard(cornerRadius: 24)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(transactions) { transaction in
                        SwipeToDeleteRow(
                            transaction: transaction,
                            currencyStyle: currencyStyle,
                            onTap: { onTapTransaction(transaction) },
                            onDelete: { deleteAction(transaction) }
                        )
                    }
                }
            }
        }
    }
}

/// Transaction row with tap-to-edit and a clear delete affordance (context menu).
/// Kept the historical name/signature because FinancialSummaryView also uses it.
struct SwipeToDeleteRow: View {
    let transaction: Transaction
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            TransactionRowView(transaction: transaction, currencyStyle: currencyStyle)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "xmark.circle.fill")
            }
        }
        .accessibilityAction(named: "Delete", onDelete)
    }
}
