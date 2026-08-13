//
//  DayPlan.swift
//  WayPoint
//

import Foundation

struct DayPlan: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var title: String
    var budgetLimit: Decimal
    var spentAmount: Decimal
    var items: [ItineraryItem]
    var currencyCode: String

    init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        budgetLimit: Decimal,
        spentAmount: Decimal,
        items: [ItineraryItem],
        currencyCode: String = "USD"
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.budgetLimit = budgetLimit
        self.spentAmount = spentAmount
        self.items = items
        self.currencyCode = currencyCode
    }

    var remainingBudget: Decimal {
        budgetLimit - spentAmount
    }

    var budgetProgress: Double {
        guard budgetLimit > 0 else { return 0 }
        let ratio = (spentAmount as NSDecimalNumber).doubleValue / (budgetLimit as NSDecimalNumber).doubleValue
        return min(max(ratio, 0), 1.2)
    }

    var isOverBudget: Bool {
        spentAmount > budgetLimit
    }

    var formattedRemaining: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: remainingBudget as NSDecimalNumber) ?? "\(currencyCode) \(remainingBudget)"
    }

    func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currencyCode) \(amount)"
    }
}
