import Foundation
import SwiftData
import Observation

// TransactionService.swift
@Observable 
@MainActor // Or use an actor for background isolation
class TransactionService {
    var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // AI Agents and Views both call this single source of truth
    func addTransaction(amount: Double, type: TransactionType, category: Category, date: Date = .now, note: String? = nil, receipt: Data? = nil) throws {
        let transaction = Transaction(amount: amount, type: type, category: category, date: date, note: note, receiptImageData: receipt)
        modelContext.insert(transaction)
        try modelContext.save()
    }
}
