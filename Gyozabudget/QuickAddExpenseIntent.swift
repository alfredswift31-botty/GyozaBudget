import AppIntents

@available(iOS 16.0, macOS 14.0, *)
struct QuickAddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add Expense"
    static var description = IntentDescription("Open the Quick Add Expense sheet in Gyoza Budget.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        if #available(iOS 18.0, macOS 15.0, *) {
            if let url = URL(string: "gyozabudget://quick-add") {
                return .result(opensIntent: OpenURLIntent(url))
            }
        }

        return .result()
    }
}
