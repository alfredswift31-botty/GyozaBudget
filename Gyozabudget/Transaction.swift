//
//  Transaction.swift
//  Gyozabudget
//
//  Created by Aung Hpone Moe on 10/04/2026.
//

import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var type: TransactionType
    var category: Category
    var date: Date
    var note: String?
    @Attribute(.externalStorage) var receiptImageData: Data?

    init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        category: Category,
        date: Date,
        note: String? = nil,
        receiptImageData: Data? = nil
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.category = category
        self.date = date
        self.note = note
        self.receiptImageData = receiptImageData
    }
}

enum TransactionType: String, CaseIterable, Codable, Identifiable {
    case income
    case expense

    var id: String { rawValue }
}

enum Category: String, CaseIterable, Codable, Identifiable {
    case food = "Food"
    case rent = "Rent"
    case travel = "Travel"
    case shopping = "Shopping"
    case subscriptions = "Subscriptions"
    case groceries = "Groceries"
    case salary = "Salary"
    case other = "Other"

    var id: String { rawValue }
    var displayName: String { rawValue }
}
