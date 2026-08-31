//
//  FeeEngine.swift
//  WayPoint
//

import Foundation

// MARK: - Centralized 3% Platform Fee & Commission Engine

struct FeeEngine {
    /// Universal 3% platform commission rate
    static let commissionRate: Double = 0.03

    /// Calculates base price, 3% platform fee, and total charged
    static func calculate(basePrice: Double) -> (base: Double, fee: Double, total: Double) {
        let fee = (basePrice * commissionRate * 100).rounded() / 100
        let total = basePrice + fee
        return (basePrice, fee, total)
    }

    /// Calculates base price, 3% platform fee, and total charged using Decimal
    static func calculate(basePrice: Decimal) -> (base: Decimal, fee: Decimal, total: Decimal) {
        let baseDouble = (basePrice as NSDecimalNumber).doubleValue
        let (b, f, t) = calculate(basePrice: baseDouble)
        return (Decimal(b), Decimal(f), Decimal(t))
    }

    /// Formats amount into currency string using LocaleManager engine
    static func format(amount: Double, currencyCode: String = "USD") -> String {
        LocaleManager.formatCurrency(amount, currencyCode: currencyCode)
    }

    /// Formats Decimal amount into currency string using LocaleManager engine
    static func format(amount: Decimal, currencyCode: String = "USD") -> String {
        LocaleManager.formatCurrency(amount, currencyCode: currencyCode)
    }
}
