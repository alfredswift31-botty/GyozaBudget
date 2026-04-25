import Foundation
import SwiftData

@Model
final class SavingsGoal {
    @Attribute(.unique) var id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var createdDate: Date?
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0,
        createdDate: Date? = Date(),
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.createdDate = createdDate
        self.isCompleted = isCompleted
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(max(currentAmount / targetAmount, 0), 1)
    }

    var displayProgress: String {
        let percent = Int(progress * 100)
        return "\(percent)%"
    }

    var progressText: String {
        "\(currentAmount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))) of \(targetAmount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))"
    }
}
