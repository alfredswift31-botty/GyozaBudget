import SwiftUI
import SwiftData
enum FinancialSummaryMode: String, Hashable {
    case balance
    case income
    case expenses

    var navigationTitle: String {
        switch self {
        case .balance:
            return "Current Balance"
        case .income:
            return "Income"
        case .expenses:
            return "Expenses"
        }
    }

    var headline: String {
        switch self {
        case .balance:
            return "Balance Overview"
        case .income:
            return "Income Summary"
        case .expenses:
            return "Expense Summary"
        }
    }

    var subtitle: String {
        switch self {
        case .balance:
            return "A quick breakdown of how income and expenses combine into your current balance."
        case .income:
            return "All recorded income transactions in one place."
        case .expenses:
            return "All recorded expense transactions in one place."
        }
    }

    var heroLabel: String {
        switch self {
        case .balance:
            return "Current balance"
        case .income:
            return "Total income"
        case .expenses:
            return "Total expenses"
        }
    }

    var transactionSectionTitle: String {
        switch self {
        case .balance:
            return "Recent Transactions"
        case .income:
            return "Income Transactions"
        case .expenses:
            return "Expense Transactions"
        }
    }

    var emptyStateText: String {
        switch self {
        case .balance:
            return "No transactions yet. Add income or expenses to build your balance."
        case .income:
            return "No income transactions yet."
        case .expenses:
            return "No expense transactions yet."
        }
    }
}

struct FinancialSummaryView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let mode: FinancialSummaryMode
    let transactions: [Transaction]
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency
    let onTapTransaction: (Transaction) -> Void
    let deleteAction: (Transaction) -> Void

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    private var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var balance: Double {
        totalIncome - totalExpenses
    }

    private var heroValue: Double {
        switch mode {
        case .balance:
            return balance
        case .income:
            return totalIncome
        case .expenses:
            return totalExpenses
        }
    }

    private var displayedTransactions: [Transaction] {
        switch mode {
        case .balance:
            return Array(transactions.prefix(5))
        case .income:
            return transactions.filter { $0.type == .income }
        case .expenses:
            return transactions.filter { $0.type == .expense }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard

                if mode == .balance {
                    balanceBreakdownCard
                }

                transactionsSection
            }
            .padding()
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(mode.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(mode.headline)
                .font(.caption.weight(.semibold))
                .foregroundColor(theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.35)

            Text(heroValue, format: currencyStyle)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(mode.subtitle)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)

            HStack {
                Text(mode.heroLabel)
                    .font(.footnote)
                    .foregroundColor(theme.textSecondary)
                Spacer()
                Text("\(displayedTransactions.count)")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.primary)
                Text(mode == .balance ? "recent" : "transactions")
                    .font(.footnote)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appPanelCard(cornerRadius: 16, emphasized: true)
    }

    private var balanceBreakdownCard: some View {
        VStack(spacing: 16) {
            summaryRow(title: "Total income", value: totalIncome)
            summaryRow(title: "Total expenses", value: totalExpenses)
            summaryRow(title: "Net balance", value: balance, emphasized: true)
        }
        .padding(22)
        .appPanelCard(cornerRadius: 16)
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.transactionSectionTitle)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)

            if displayedTransactions.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "list.bullet.rectangle",
                    description: Text(mode.emptyStateText)
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(displayedTransactions) { transaction in
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryRow(title: String, value: Double, emphasized: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.footnote.weight(emphasized ? .semibold : .regular))
                .foregroundColor(emphasized ? .primary : theme.textSecondary)
            Spacer()
            Text(value, format: currencyStyle)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundColor(.primary)
        }
    }
}
