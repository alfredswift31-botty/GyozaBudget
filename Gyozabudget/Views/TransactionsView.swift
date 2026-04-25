import SwiftUI

struct TransactionsView: View {
    @Environment(\.colorScheme) private var colorScheme
    let transactions: [Transaction]
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency
    let onTapTransaction: (Transaction) -> Void
    let deleteAction: (Transaction) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Transactions")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.primary)
                        Text("Full history of your expenses and income.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(transactions.count)")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 4)

                if transactions.isEmpty {
                    Text("No transactions yet. Add one to get started.")
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
                    VStack(spacing: 12) {
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
            .padding()
        }
        .background(Color.appBackground(for: colorScheme).ignoresSafeArea())
    }
}
