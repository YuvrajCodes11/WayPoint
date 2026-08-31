//
//  BudgetModel.swift
//  WayPoint
//

import Foundation

// MARK: - Currency Converter Engine

struct CurrencyConverter {
    // Standard exchange rates relative to 1 USD
    static let exchangeRatesToUSD: [String: Double] = [
        "USD": 1.0,
        "JPY": 151.80,
        "EUR": 0.92,
        "GBP": 0.79,
        "CAD": 1.36,
        "AUD": 1.52,
        "SGD": 1.35,
        "INR": 83.50
    ]

    static let currencySymbols: [String: String] = [
        "USD": "$",
        "JPY": "¥",
        "EUR": "€",
        "GBP": "£",
        "CAD": "CA$",
        "AUD": "A$",
        "SGD": "S$",
        "INR": "₹"
    ]

    static func convert(amount: Decimal, from fromCurrency: String, to toCurrency: String) -> Decimal {
        let fromRate = exchangeRatesToUSD[fromCurrency.uppercased()] ?? 1.0
        let toRate = exchangeRatesToUSD[toCurrency.uppercased()] ?? 1.0

        let amountDouble = (amount as NSDecimalNumber).doubleValue
        let usdAmount = amountDouble / fromRate
        let targetAmount = usdAmount * toRate

        return Decimal(string: String(format: "%.2f", targetAmount)) ?? Decimal(targetAmount)
    }

    static func symbol(for currencyCode: String) -> String {
        currencySymbols[currencyCode.uppercased()] ?? currencyCode
    }

    static func format(amount: Decimal, currencyCode: String) -> String {
        LocaleManager.formatCurrency(amount, currencyCode: currencyCode)
    }
}

// MARK: - Scanned Receipt Model

struct ScannedReceipt: Identifiable, Codable, Hashable {
    let id: UUID
    var merchantName: String
    var detectedCurrency: String
    var detectedSymbol: String
    var originalAmount: Decimal
    var convertedAmount: Decimal
    var baseCurrencyCode: String
    var category: ItemCategory
    var timestamp: Date
    var rawText: String

    init(
        id: UUID = UUID(),
        merchantName: String,
        detectedCurrency: String,
        detectedSymbol: String,
        originalAmount: Decimal,
        convertedAmount: Decimal,
        baseCurrencyCode: String = "USD",
        category: ItemCategory = .dining,
        timestamp: Date = Date(),
        rawText: String = ""
    ) {
        self.id = id
        self.merchantName = merchantName
        self.detectedCurrency = detectedCurrency
        self.detectedSymbol = detectedSymbol
        self.originalAmount = originalAmount
        self.convertedAmount = convertedAmount
        self.baseCurrencyCode = baseCurrencyCode
        self.category = category
        self.timestamp = timestamp
        self.rawText = rawText
    }

    var formattedOriginal: String {
        CurrencyConverter.format(amount: originalAmount, currencyCode: detectedCurrency)
    }

    var formattedConverted: String {
        CurrencyConverter.format(amount: convertedAmount, currencyCode: baseCurrencyCode)
    }
}

// MARK: - Demo Test Cases for Simulator Testing

struct ReceiptDemoSample: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let receipt: ScannedReceipt

    static let samples: [ReceiptDemoSample] = [
        ReceiptDemoSample(
            title: "Tokyo Ramen Receipt (¥1,800)",
            icon: "🧾",
            receipt: ScannedReceipt(
                merchantName: "Ichiran Ramen Shibuya",
                detectedCurrency: "JPY",
                detectedSymbol: "¥",
                originalAmount: 1800,
                convertedAmount: CurrencyConverter.convert(amount: 1800, from: "JPY", to: "USD"),
                baseCurrencyCode: "USD",
                category: .dining,
                rawText: "ICHIRAN RAMEN SHIBUYA\n1x Tonkotsu Ramen ¥1,400\n1x Extra Chashu ¥400\nTOTAL: ¥1,800"
            )
        ),
        ReceiptDemoSample(
            title: "Wagyu Omakase Dinner (¥15,000)",
            icon: "🥩",
            receipt: ScannedReceipt(
                merchantName: "Ginza Wagyu Omakase",
                detectedCurrency: "JPY",
                detectedSymbol: "¥",
                originalAmount: 15000,
                convertedAmount: CurrencyConverter.convert(amount: 15000, from: "JPY", to: "USD"),
                baseCurrencyCode: "USD",
                category: .dining,
                rawText: "GINZA WAGYU OMAKASE\nChef's Tasting Course ¥13,500\nSake Pairing ¥1,500\nTOTAL AMOUNT: ¥15,000"
            )
        ),
        ReceiptDemoSample(
            title: "Shibuya Drip Coffee (¥650)",
            icon: "☕",
            receipt: ScannedReceipt(
                merchantName: "Shibuya Drip Roasters",
                detectedCurrency: "JPY",
                detectedSymbol: "¥",
                originalAmount: 650,
                convertedAmount: CurrencyConverter.convert(amount: 650, from: "JPY", to: "USD"),
                baseCurrencyCode: "USD",
                category: .dining,
                rawText: "SHIBUYA DRIP ROASTERS\n1x Hand Drip Latte ¥650\nTOTAL: ¥650"
            )
        )
    ]
}

// MARK: - Vision OCR & Text Parsing Engine

struct ReceiptOCRParser {
    static func parseText(_ text: String, baseCurrency: String = "USD") -> ScannedReceipt {
        let detectedSymbol: String
        let detectedCurrency: String

        let lower = text.lowercased()
        if text.contains("¥") || lower.contains("jpy") || lower.contains("yen") || text.contains("円") {
            detectedSymbol = "¥"
            detectedCurrency = "JPY"
        } else if text.contains("€") || lower.contains("eur") || lower.contains("euro") {
            detectedSymbol = "€"
            detectedCurrency = "EUR"
        } else if text.contains("£") || lower.contains("gbp") || lower.contains("pound") {
            detectedSymbol = "£"
            detectedCurrency = "GBP"
        } else if text.contains("₹") || lower.contains("inr") || lower.contains("rupee") {
            detectedSymbol = "₹"
            detectedCurrency = "INR"
        } else {
            detectedSymbol = "$"
            detectedCurrency = "USD"
        }

        // Extract numbers using regular expressions with integer vs fractional decimal handling
        let extractedNumbers = extractAmounts(from: text, isZeroDecimalCurrency: detectedCurrency == "JPY")
        let amount = extractedNumbers.max() ?? (detectedCurrency == "JPY" ? 1500.0 : 15.00)
        let originalDecimal = Decimal(amount)
        let convertedDecimal = CurrencyConverter.convert(amount: originalDecimal, from: detectedCurrency, to: baseCurrency)

        let category = detectCategory(from: text)
        let merchant = extractMerchantName(from: text)

        return ScannedReceipt(
            merchantName: merchant,
            detectedCurrency: detectedCurrency,
            detectedSymbol: detectedSymbol,
            originalAmount: originalDecimal,
            convertedAmount: convertedDecimal,
            baseCurrencyCode: baseCurrency,
            category: category,
            rawText: text
        )
    }

    private static func extractAmounts(from text: String, isZeroDecimalCurrency: Bool) -> [Double] {
        // Optical regex matching currency symbols (¥, $, €, £) or ISO codes and formatted numbers
        let pattern = #"(?:[¥$€£]|jpy|usd|eur|gbp)?\s*([0-9]{1,3}(?:[,\.][0-9]{3})*(?:[\.,][0-9]{2})?|[0-9]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }

        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))

        var results: [Double] = []
        for match in matches {
            if match.numberOfRanges > 1 {
                var rawNum = nsString.substring(with: match.range(at: 1))
                if isZeroDecimalCurrency {
                    // For zero-decimal currencies like JPY, strip all commas and periods as thousand separators
                    rawNum = rawNum.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: "")
                } else {
                    // For 2-decimal currencies, normalize thousands commas (e.g., 1,800.00 -> 1800.00)
                    if rawNum.contains(",") && rawNum.contains(".") {
                        rawNum = rawNum.replacingOccurrences(of: ",", with: "")
                    } else if rawNum.contains(",") && !rawNum.contains(".") {
                        // Handle European comma decimal (e.g. 18,50 -> 18.50)
                        let parts = rawNum.components(separatedBy: ",")
                        if parts.count == 2 && parts[1].count == 2 {
                            rawNum = parts[0] + "." + parts[1]
                        } else {
                            rawNum = rawNum.replacingOccurrences(of: ",", with: "")
                        }
                    }
                }
                if let val = Double(rawNum), val > 0 {
                    results.append(val)
                }
            }
        }
        return results
    }

    private static func detectCategory(from text: String) -> ItemCategory {
        let lower = text.lowercased()
        if lower.contains("ramen") || lower.contains("omakase") || lower.contains("coffee") || lower.contains("dining") || lower.contains("cafe") || lower.contains("restaurant") {
            return .dining
        } else if lower.contains("train") || lower.contains("metro") || lower.contains("subway") || lower.contains("taxi") || lower.contains("suica") || lower.contains("pasmo") {
            return .transit
        } else if lower.contains("museum") || lower.contains("shrine") || lower.contains("temple") || lower.contains("ticket") || lower.contains("tour") {
            return .sightseeing
        } else if lower.contains("store") || lower.contains("ginza") || lower.contains("bikit") || lower.contains("tax free") || lower.contains("mall") {
            return .shopping
        }
        return .dining
    }

    private static func extractMerchantName(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if let firstLine = lines.first, firstLine.count < 35 {
            return firstLine.capitalized
        }
        return "Local Venue Receipt"
    }
}
