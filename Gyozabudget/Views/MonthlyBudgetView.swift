import SwiftUI

struct MonthlyBudgetView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let items: [BudgetSection.BudgetData]
    let hasTransactions: Bool
    let currencyStyle: FloatingPointFormatStyle<Double>.Currency
    let onEdit: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var theme: AppTheme {
        themeManager.currentTheme
    }

    private var categoriesWithTargets: [BudgetSection.BudgetData] {
        items.filter { $0.target > 0 }
    }

    private var totalTarget: Double {
        categoriesWithTargets.map { $0.target }.reduce(0, +)
    }

    private var totalActual: Double {
        categoriesWithTargets.map { $0.actual }.reduce(0, +)
    }

    private var overBudgetCount: Int {
        categoriesWithTargets.filter { $0.actual > $0.target }.count
    }

    private var nearBudgetCount: Int {
        categoriesWithTargets.filter { $0.actual > $0.target * 0.9 && $0.actual <= $0.target }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                summaryView

                if categoriesWithTargets.isEmpty {
                    emptyState
                } else {
                    ForEach(items) { item in
                        budgetRow(item)
                    }
                }
            }
            .padding()
        }
        .background(Color.appBackground(for: colorScheme).ignoresSafeArea())
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Manage") {
                    onEdit()
                }
                .font(.subheadline.weight(.semibold))
            }
#else
            ToolbarItem {
                Button("Manage") {
                    onEdit()
                }
                .font(.subheadline.weight(.semibold))
            }
#endif
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Budget")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(theme.textPrimary)
            Text("Review your budget goals, progress, and overspending at a glance.")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summaryView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(overBudgetCount > 0 ? "Over budget in \(overBudgetCount) categories" : nearBudgetCount > 0 ? "Near limit in \(nearBudgetCount) categories" : categoriesWithTargets.isEmpty ? "No monthly budgets yet" : "Budget on track")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                Text("\(totalActual, format: currencyStyle) spent of \(totalTarget, format: currencyStyle)")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }
            Spacer()
            Text(categoriesWithTargets.isEmpty ? "Set targets" : overBudgetCount > 0 ? "Review" : "On track")
                .font(.caption.weight(.semibold))
                .foregroundColor(theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(theme.subtleAccent)
                )
        }
        .padding(20)
        .appPanelCard(cornerRadius: 24, emphasized: true)
    }

    private func budgetRow(_ item: BudgetSection.BudgetData) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.category.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Text(statusLabel(for: item))
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(statusColor(for: item))
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.textSecondary)
                    Text(item.target > 0 ? item.target.formatted(currencyStyle) : "–")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Spent")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.textSecondary)
                    Text(item.actual.formatted(currencyStyle))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                }
            }

            Text(remainingText(for: item))
                .font(.footnote)
                .foregroundColor(theme.textSecondary)

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
        .padding(18)
        .appPanelCard(cornerRadius: 24)
    }

    private func statusLabel(for item: BudgetSection.BudgetData) -> String {
        guard item.target > 0 else { return "No target" }
        if item.actual > item.target {
            return "Over by " + (item.actual - item.target).formatted(currencyStyle)
        }
        if item.actual > item.target * 0.9 {
            return "Near limit"
        }
        return "Under budget"
    }

    private func remainingText(for item: BudgetSection.BudgetData) -> String {
        guard item.target > 0 else { return "Add a monthly target to track this category." }
        let remaining = item.target - item.actual
        if remaining < 0 {
            return "Exceeded by " + abs(remaining).formatted(currencyStyle)
        }
        return "Remaining " + remaining.formatted(currencyStyle)
    }

    private func statusColor(for item: BudgetSection.BudgetData) -> Color {
        guard item.target > 0 else { return colorScheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.3) }
        if item.actual > item.target {
            return colorScheme == .dark ? Color.white.opacity(0.9) : Color.black.opacity(0.8)
        }
        if item.actual > item.target * 0.9 {
            return colorScheme == .dark ? Color.white.opacity(0.75) : Color.black.opacity(0.65)
        }
        return colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.45)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(hasTransactions ? "Set your first budget to guide your spending." : "Add a transaction first, then set your budget.")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if hasTransactions {
                Button(action: onEdit) {
                    Text("Set Budget")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(AppPrimaryButtonStyle())
            }
        }
        .padding(20)
        .appPanelCard(cornerRadius: 24)
    }
}
