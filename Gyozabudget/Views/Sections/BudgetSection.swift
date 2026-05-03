import SwiftUI

struct BudgetSection: View {
    @Environment(\.colorScheme) private var colorScheme
    struct BudgetData: Identifiable {
        var id: Category { category }
        let category: Category
        let actual: Double
        let target: Double
    }

    let items: [BudgetData]
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency
    let editAction: () -> Void

    private var hasTargets: Bool {
        items.contains { $0.target > 0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Budget")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                    Text("Compare current month spending to each category goal.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Manage") {
                    editAction()
                }
                .font(.subheadline.weight(.semibold))
            }
            .padding(.bottom, 14)

            if items.isEmpty {
                Text("Create budget targets to monitor monthly spending.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            } else {
                VStack(spacing: 18) {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(item.category.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                if item.target > 0 {
                                    Text(item.target, format: currencyStyle)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                } else {
                                    Text("No plan")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text(item.target > 0 ? "Spent " + item.actual.formatted(currencyStyle) + " of " + item.target.formatted(currencyStyle) : "No budget target set.")
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            GeometryReader { geo in
                                let progress = item.target > 0 ? min(item.actual / item.target, 1) : 0
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.appProgressBackground(for: colorScheme))
                                    Capsule()
                                        .fill(Color.appProgressFill(for: colorScheme, isPrimary: item.target > 0))
                                        .frame(width: max(geo.size.width * progress, item.target > 0 ? 8 : 0), height: 8)
                                }
                            }
                            .frame(height: 10)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.appSurface(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.appBorder(for: colorScheme), lineWidth: 1)
        )
    }
}
