import SwiftUI

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
    @Environment(\.colorScheme) private var colorScheme

    let mode: FinancialSummaryMode
    let transactions: [Transaction]
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency
    let onTapTransaction: (Transaction) -> Void
    let deleteAction: (Transaction) -> Void

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
        .background(Color.appBackground(for: colorScheme).ignoresSafeArea())
        .navigationTitle(mode.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(mode.headline)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.appSecondaryText(for: colorScheme))
                .textCase(.uppercase)
                .tracking(0.35)

            Text(heroValue, format: currencyStyle)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(mode.subtitle)
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText(for: colorScheme))

            HStack {
                Text(mode.heroLabel)
                    .font(.footnote)
                    .foregroundColor(Color.appSecondaryText(for: colorScheme))
                Spacer()
                Text("\(displayedTransactions.count)")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.primary)
                Text(mode == .balance ? "recent" : "transactions")
                    .font(.footnote)
                    .foregroundColor(Color.appSecondaryText(for: colorScheme))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.appSurface(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.appBorder(for: colorScheme), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.04), radius: 16, x: 0, y: 8)
    }

    private var balanceBreakdownCard: some View {
        VStack(spacing: 16) {
            summaryRow(title: "Current balance", value: balance)
            summaryRow(title: "Total income", value: totalIncome)
            summaryRow(title: "Total expenses", value: totalExpenses)
            summaryRow(title: "Net result", value: balance, emphasized: true)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.appSurface(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.appBorder(for: colorScheme), lineWidth: 1)
        )
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.transactionSectionTitle)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)

            if displayedTransactions.isEmpty {
                Text(mode.emptyStateText)
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.appSurface(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.appBorder(for: colorScheme), lineWidth: 1)
                    )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(displayedTransactions) { transaction in
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryRow(title: String, value: Double, emphasized: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.footnote.weight(emphasized ? .semibold : .regular))
                .foregroundColor(emphasized ? .primary : Color.appSecondaryText(for: colorScheme))
            Spacer()
            Text(value, format: currencyStyle)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
    }
}
