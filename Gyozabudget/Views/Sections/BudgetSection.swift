import Foundation

/// Namespace only: the old BudgetSection view was never instantiated, but
/// `BudgetSection.BudgetData` is used by ContentView and MonthlyBudgetView.
enum BudgetSection {
    struct BudgetData: Identifiable {
        var id: Category { category }
        let category: Category
        let actual: Double
        let target: Double
    }
}
