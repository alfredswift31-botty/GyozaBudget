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

struct SwipeToDeleteRow: View {
    let transaction: Transaction
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var rowWidth: CGFloat = 300

    private let rowCornerRadius: CGFloat = 22
    private let deleteRevealThreshold: CGFloat = 8

    private var deleteBackgroundOpacity: Double {
        guard offset < -deleteRevealThreshold else { return 0 }
        return min(Double((abs(offset) - deleteRevealThreshold) / 72), 1)
    }

    var body: some View {
        let rowShape = RoundedRectangle(cornerRadius: rowCornerRadius, style: .continuous)

        ZStack(alignment: .trailing) {
            if offset < -deleteRevealThreshold {
                rowShape
                    .fill(Color.red)
                    .overlay(
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .font(.title3.weight(.semibold))
                            .padding(.trailing, 24),
                        alignment: .trailing
                    )
                    .opacity(deleteBackgroundOpacity)
                    .clipShape(rowShape)
            }

            TransactionRowView(transaction: transaction, currencyStyle: currencyStyle)
                .contentShape(Rectangle())
                .clipShape(rowShape)
                .onTapGesture {
                    if offset < 0 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { offset = 0 }
                    } else {
                        onTap()
                    }
                }
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if value.translation.width < -80 {
                                    offset = -(rowWidth + 20)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        onDelete()
                                    }
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
        }
        .clipShape(rowShape)
        .background(
            GeometryReader { geo in
                Color.clear.onAppear { rowWidth = geo.size.width }
            }
        )
    }
}
