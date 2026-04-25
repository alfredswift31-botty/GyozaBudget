import SwiftUI

struct CategoryChartSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isExpanded = false
    let totals: [(category: Category, amount: Double)]
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    private var maxAmount: Double {
        totals.map { $0.amount }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Spending by Category")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(theme.premiumCardTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(theme.premiumCardTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                if totals.isEmpty {
                    Text("Add expense transactions to see the chart.")
                        .font(.subheadline)
                        .foregroundColor(theme.premiumCardTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 18) {
                        ForEach(totals, id: \.category) { item in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(item.category.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(theme.premiumCardTextPrimary)
                                    Spacer()
                                    Text(item.amount, format: currencyStyle)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundColor(theme.premiumCardTextPrimary)
                                }

                                GeometryReader { geo in
                                    let width = geo.size.width * CGFloat(item.amount / maxAmount)
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(theme.premiumCardTextSecondary.opacity(0.16))
                                        Capsule()
                                            .fill(theme.accent)
                                            .frame(width: max(width, 12), height: 8)
                                    }
                                }
                                .frame(height: 10)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .premiumCard(cornerRadius: 24, glowEnabled: false)
    }
}
