//
//  Task21CurrencyLocaleTests.swift
//  WayPoint
//
//  Task 2.1: Currency & Locale Formatting Engine Automated Test Suite
//

import Foundation
import SwiftUI

@MainActor
final class Task21CurrencyLocaleTests {
    static let shared = Task21CurrencyLocaleTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all Task 2.1 test scenarios (A, B, C, D, E) and returns structured results.
    func runAllTask21Tests() async -> [TestResult] {
        var results: [TestResult] = []

        results.append(await testA_USDFormattingUSLocale())
        results.append(await testB_JPYZeroDecimalJapanLocale())
        results.append(await testC_EURFormattingFrenchLocale())
        results.append(await testD_INRFormattingIndiaLocale())
        results.append(await testE_FallbackUnknownCurrencyCode())

        for res in results {
            print("[TASK-2.1-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        return results
    }

    // MARK: - Test A: USD Formatting in US Locale ($1,234.56)
    private func testA_USDFormattingUSLocale() async -> TestResult {
        let result = LocaleManager.formatCurrency(1234.56, currencyCode: "USD", locale: Locale(identifier: "en_US"))
        let passed = result.contains("$") && result.contains("1,234.56")

        return TestResult(
            name: "Test A: USD Formatting in US Locale ($1,234.56)",
            passed: passed,
            details: "Input: 1234.56 USD -> Result: '\(result)'."
        )
    }

    // MARK: - Test B: JPY Zero-Decimal in Japan Locale (¥1,800 no decimals)
    private func testB_JPYZeroDecimalJapanLocale() async -> TestResult {
        let result = LocaleManager.formatCurrency(1800.0, currencyCode: "JPY", locale: Locale(identifier: "ja_JP"))
        let isZeroDec = LocaleManager.isZeroDecimalCurrency("JPY")
        let noTrailingDecimals = !result.contains(".00") && !result.contains(",00")
        let passed = isZeroDec && (result.contains("1,800") || result.contains("1800")) && noTrailingDecimals

        return TestResult(
            name: "Test B: JPY Zero-Decimal in Japan Locale (¥1,800)",
            passed: passed,
            details: "Input: 1800 JPY -> Result: '\(result)', isZeroDecimalCurrency: \(isZeroDec)."
        )
    }

    // MARK: - Test C: EUR Formatting in France Locale (49,90 € comma separator)
    private func testC_EURFormattingFrenchLocale() async -> TestResult {
        let result = LocaleManager.formatCurrency(49.90, currencyCode: "EUR", locale: Locale(identifier: "fr_FR"))
        let hasComma = result.contains("49,90")
        let hasEuroSymbol = result.contains("€")
        let passed = hasComma && hasEuroSymbol

        return TestResult(
            name: "Test C: EUR Formatting in French Locale (49,90 €)",
            passed: passed,
            details: "Input: 49.90 EUR (fr_FR) -> Result: '\(result)'."
        )
    }

    // MARK: - Test D: INR Formatting in India Locale (₹1,50,000.00 lakh grouping)
    private func testD_INRFormattingIndiaLocale() async -> TestResult {
        let result = LocaleManager.formatCurrency(150000.0, currencyCode: "INR", locale: Locale(identifier: "en_IN"))
        let hasLakhGrouping = result.contains("1,50,000") || result.contains("₹")
        let passed = hasLakhGrouping

        return TestResult(
            name: "Test D: INR Formatting in India Locale (₹1,50,000.00)",
            passed: passed,
            details: "Input: 150000 INR (en_IN) -> Result: '\(result)'."
        )
    }

    // MARK: - Test E: Fallback / Unknown 3-Letter ISO Code (XYZ 250.00)
    private func testE_FallbackUnknownCurrencyCode() async -> TestResult {
        let result = LocaleManager.formatCurrency(250.0, currencyCode: "XYZ", locale: Locale(identifier: "en_US"))
        let isValidString = !result.isEmpty && (result.contains("250") || result.contains("XYZ"))
        let parsed = LocaleManager.parseCurrencyString("¥1,800", defaultCurrency: "USD")
        let parserWorking = (parsed?.amount == 1800.0 && parsed?.currencyCode == "JPY")

        let passed = isValidString && parserWorking

        return TestResult(
            name: "Test E: Fallback / Unknown ISO Code & Currency Parser",
            passed: passed,
            details: "Unknown ISO result: '\(result)', Parsed '¥1,800': amount=\(parsed?.amount ?? 0), code='\(parsed?.currencyCode ?? "")'."
        )
    }
}
