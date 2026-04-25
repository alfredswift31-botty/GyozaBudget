//
//  Item.swift
//  Gyozabudget
//
//  Created by Aung Hpone Moe on 10/04/2026.
//

import Foundation
import SwiftData

@Model
final class BudgetTarget {
    @Attribute(.unique) var id: UUID
    var category: Category
    var amount: Double
    var month: Date

    init(
        id: UUID = UUID(),
        category: Category,
        amount: Double,
        month: Date
    ) {
        self.id = id
        self.category = category
        self.amount = amount
        self.month = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: month)) ?? month
    }
}

extension Category {
    static var budgetCategories: [Category] {
        [.food, .rent, .travel, .shopping, .subscriptions, .groceries, .other]
    }
}

