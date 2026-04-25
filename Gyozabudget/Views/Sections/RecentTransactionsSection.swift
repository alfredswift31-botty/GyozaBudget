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
                        Button("Add Transaction", action: onPrimaryAction)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .buttonStyle(AppPrimaryButtonStyle())
                    }
                }
                    .padding(20)
                    .premiumCard(cornerRadius: 24, glowEnabled: false)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(transactions) { transaction in
                        TransactionRowView(transaction: transaction, currencyStyle: currencyStyle)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onTapTransaction(transaction)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteAction(transaction)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }
}
