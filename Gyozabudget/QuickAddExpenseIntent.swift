import AppIntents

struct QuickAddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add Expense"
    static var description = IntentDescription("Open the Quick Add Expense sheet in Gyoza Budget.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        if let url = URL(string: "gyozabudget://quick-add") {
            return .result(opensIntent: OpenURLIntent(url))
        }
        return .result()
    }
}
