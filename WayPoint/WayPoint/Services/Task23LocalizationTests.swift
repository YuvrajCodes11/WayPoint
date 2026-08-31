//
//  Task23LocalizationTests.swift
//  WayPoint
//
//  Task 2.3: String Catalogs & Localization Architecture Automated Test Suite
//

import Foundation
import SwiftUI

@MainActor
final class Task23LocalizationTests {
    static let shared = Task23LocalizationTests()

    private init() {}

    struct TestResult {
        let name: String
        let passed: Bool
        let details: String
    }

    /// Runs all Task 2.3 test scenarios (A, B, C, D) and returns structured results.
    func runAllTask23Tests() async -> [TestResult] {
        var results: [TestResult] = []

        results.append(await testA_EnglishBaselineKeyResolution())
        results.append(await testB_JapaneseKeyResolution())
        results.append(await testC_SpanishFrenchGermanKeyResolution())
        results.append(await testD_DynamicParameterLocalization())

        for res in results {
            print("[TASK-2.3-TEST] \(res.passed ? "✅ PASS" : "❌ FAIL") - \(res.name): \(res.details)")
        }

        return results
    }

    // MARK: - Test A: English Baseline Key Resolution
    private func testA_EnglishBaselineKeyResolution() async -> TestResult {
        let keys = ["Dashboard", "Radar", "Pass Vault", "Settings", "Intelligent Re-balance", "Daily Budget", "Scan Receipt"]
        var passedKeys = 0

        for key in keys {
            let res = LocalizationManager.string(forKey: key, languageCode: "en")
            if !res.isEmpty && res == key {
                passedKeys += 1
            }
        }

        let passed = (passedKeys == keys.count)

        return TestResult(
            name: "Test A: English Baseline Key Resolution",
            passed: passed,
            details: "Resolved \(passedKeys)/\(keys.count) baseline English keys."
        )
    }

    // MARK: - Test B: Japanese Key Resolution
    private func testB_JapaneseKeyResolution() async -> TestResult {
        let rebalanceJA = LocalizationManager.string(forKey: "Intelligent Re-balance", languageCode: "ja")
        let startLiveJA = LocalizationManager.string(forKey: "Start Live", languageCode: "ja")
        let passVaultJA = LocalizationManager.string(forKey: "Pass Vault", languageCode: "ja")
        let dailyBudgetJA = LocalizationManager.string(forKey: "Daily Budget", languageCode: "ja")

        let isRebalanceValid = (rebalanceJA == "AI自動リバランス")
        let isStartLiveValid = (startLiveJA == "ライブ開始")
        let isPassVaultValid = (passVaultJA == "デジタルパス")
        let isDailyBudgetValid = (dailyBudgetJA == "日別予算")

        let passed = isRebalanceValid && isStartLiveValid && isPassVaultValid && isDailyBudgetValid

        return TestResult(
            name: "Test B: Japanese Key Resolution (ja)",
            passed: passed,
            details: "Intelligent Re-balance -> '\(rebalanceJA)', Start Live -> '\(startLiveJA)', Pass Vault -> '\(passVaultJA)'."
        )
    }

    // MARK: - Test C: Spanish / French / German Key Resolution (No **key** Placeholders)
    private func testC_SpanishFrenchGermanKeyResolution() async -> TestResult {
        let testKey = "Intelligent Re-balance"

        let esVal = LocalizationManager.string(forKey: testKey, languageCode: "es")
        let frVal = LocalizationManager.string(forKey: testKey, languageCode: "fr")
        let deVal = LocalizationManager.string(forKey: testKey, languageCode: "de")

        let noFallbackES = !esVal.contains("**") && esVal == "Reequilibrio Inteligente"
        let noFallbackFR = !frVal.contains("**") && frVal == "Rééquilibrage Intelligent"
        let noFallbackDE = !deVal.contains("**") && deVal == "Intelligenter Neuausgleich"

        let passed = noFallbackES && noFallbackFR && noFallbackDE

        return TestResult(
            name: "Test C: Spanish / French / German Key Resolution",
            passed: passed,
            details: "ES: '\(esVal)', FR: '\(frVal)', DE: '\(deVal)'."
        )
    }

    // MARK: - Test D: Dynamic Parameter Localization ("Day %lld", "%@ spent of %@")
    private func testD_DynamicParameterLocalization() async -> TestResult {
        let dayEN = LocalizationManager.formattedString(forKey: "Day %lld", languageCode: "en", arguments: [3])
        let dayJA = LocalizationManager.formattedString(forKey: "Day %lld", languageCode: "ja", arguments: [3])
        let dayES = LocalizationManager.formattedString(forKey: "Day %lld", languageCode: "es", arguments: [3])

        let budgetEN = LocalizationManager.formattedString(forKey: "%@ spent of %@", languageCode: "en", arguments: ["$45.00", "$100.00"])
        let budgetJA = LocalizationManager.formattedString(forKey: "%@ spent of %@", languageCode: "ja", arguments: ["$45.00", "$100.00"])

        let isDayENValid = (dayEN == "Day 3")
        let isDayJAValid = (dayJA == "3日目")
        let isDayESValid = (dayES == "Día 3")

        let isBudgetENValid = (budgetEN == "$45.00 spent of $100.00")
        let isBudgetJAValid = (budgetJA == "$45.00 / $100.00")

        let passed = isDayENValid && isDayJAValid && isDayESValid && isBudgetENValid && isBudgetJAValid

        return TestResult(
            name: "Test D: Dynamic Parameter Localization",
            passed: passed,
            details: "Day 3 (EN/JA/ES): '\(dayEN)' / '\(dayJA)' / '\(dayES)'. Budget (EN/JA): '\(budgetEN)' / '\(budgetJA)'."
        )
    }
}
