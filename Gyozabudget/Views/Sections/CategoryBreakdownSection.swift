import SwiftUI

struct CategoryBreakdownSection: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isExpanded = false
    let totals: [(category: Category, amount: Double)]
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Category Breakdown")
                        .font(.title3.weight(.semibold))
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
                    Text("No expense categories yet.")
                        .font(.subheadline)
                        .foregroundColor(theme.premiumCardTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 10)
                        .padding(20)
                } else {
                    VStack(spacing: 0) {
                        ForEach(totals.indices, id: \.self) { index in
                            let item = totals[index]
                            HStack {
                                Text(item.category.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(theme.premiumCardTextPrimary)
                                Spacer()
                                Text(item.amount, format: currencyStyle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(theme.premiumCardTextPrimary)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 18)

                            if index < totals.count - 1 {
                                Divider()
                                    .overlay(theme.premiumCardTextSecondary.opacity(0.16))
                                    .padding(.leading, 18)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
        .padding(18)
        .premiumCard(cornerRadius: 16)
    }
}
