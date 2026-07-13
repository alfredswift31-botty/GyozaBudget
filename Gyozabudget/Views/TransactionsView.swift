import SwiftUI
import SwiftData

struct TransactionsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let transactions: [Transaction]
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency
    let onTapTransaction: (Transaction) -> Void
    let deleteAction: (Transaction) -> Void

    @State private var searchText = ""

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    private var filteredTransactions: [Transaction] {
        guard !searchText.isEmpty else { return transactions }
        return transactions.filter { transaction in
            (transaction.note?.localizedCaseInsensitiveContains(searchText) ?? false)
                || transaction.category.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var monthGroups: [(month: String, transactions: [Transaction])] {
        var groups: [(month: String, transactions: [Transaction])] = []
        for transaction in filteredTransactions {
            let key = transaction.date.formatted(.dateTime.month(.wide).year())
            if let index = groups.firstIndex(where: { $0.month == key }) {
                groups[index].transactions.append(transaction)
            } else {
                groups.append((month: key, transactions: [transaction]))
            }
        }
        return groups
    }

    var body: some View {
        List {
            header
                .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            ForEach(monthGroups, id: \.month) { group in
                Section {
                    ForEach(group.transactions) { transaction in
                        Button {
                            onTapTransaction(transaction)
                        } label: {
                            TransactionRowView(transaction: transaction, currencyStyle: currencyStyle)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .transactionDeleteSwipe(tint: theme.destructive) {
                            deleteAction(transaction)
                        }
                    }
                } header: {
                    Text(group.month)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.background.ignoresSafeArea())
        .searchable(text: $searchText, prompt: "Search notes or categories")
        .overlay {
            if transactions.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Add one to get started.")
                )
            } else if filteredTransactions.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Transactions")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(theme.textPrimary)
                Text("Full history of your expenses and income.")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }
            Spacer()
            Text("\(transactions.count)")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundColor(theme.textPrimary)
        }
    }
}
