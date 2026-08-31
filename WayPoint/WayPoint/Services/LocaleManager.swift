//
//  LocaleManager.swift
//  WayPoint
//
//  Task 2.1 & Task 2.2: Currency, Locale Formatting & Timezone Date-Line Engine
//

import Foundation

public struct LocaleManager {

    // MARK: - Currency Formatting Engine

    /// Zero-decimal currencies that should not display fractional digits (e.g. JPY, KRW, VND)
    public static func isZeroDecimalCurrency(_ currencyCode: String) -> Bool {
        let zeroDecimalCodes: Set<String> = [
            "JPY", "KRW", "VND", "CLP", "PYG", "UGX", "RWF", "BIF",
            "DJF", "GNF", "KMF", "MGA", "XAF", "XOF", "XPF"
        ]
        return zeroDecimalCodes.contains(currencyCode.uppercased())
    }

    /// Formats a Double amount with locale-aware grouping separators and zero/two decimal precision.
    public static func formatCurrency(_ amount: Double, currencyCode: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode.uppercased()
        formatter.locale = locale

        if isZeroDecimalCurrency(currencyCode) {
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
        } else {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
        }

        if let formatted = formatter.string(from: NSNumber(value: amount)) {
            return formatted
        }

        // Fallback for custom or unmapped 3-letter ISO codes
        let fallbackSymbol = CurrencyConverter.symbol(for: currencyCode)
        let formattedNum = isZeroDecimalCurrency(currencyCode)
            ? String(format: "%.0f", amount)
            : String(format: "%.2f", amount)
        return "\(fallbackSymbol)\(formattedNum)"
    }

    /// Formats a Decimal amount with locale-aware grouping separators and zero/two decimal precision.
    public static func formatCurrency(_ amount: Decimal, currencyCode: String, locale: Locale = .current) -> String {
        formatCurrency((amount as NSDecimalNumber).doubleValue, currencyCode: currencyCode, locale: locale)
    }

    /// Safely parses an input currency string (e.g. "¥1,800", "$150.50", "49,90 €", "₹1,50,000.00") into amount and currencyCode.
    public static func parseCurrencyString(_ input: String, defaultCurrency: String = "USD") -> (amount: Double, currencyCode: String)? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var detectedCurrency = defaultCurrency
        let upper = trimmed.uppercased()

        let currencyMap: [String: String] = [
            "$": "USD", "USD": "USD",
            "¥": "JPY", "JPY": "JPY", "円": "JPY",
            "€": "EUR", "EUR": "EUR",
            "£": "GBP", "GBP": "GBP",
            "₹": "INR", "INR": "INR",
            "A$": "AUD", "AUD": "AUD",
            "C$": "CAD", "CAD": "CAD"
        ]

        for (symbol, code) in currencyMap {
            if trimmed.contains(symbol) || upper.contains(code) {
                detectedCurrency = code
                break
            }
        }

        let isZeroDec = isZeroDecimalCurrency(detectedCurrency)
        let pattern = #"[0-9][0-9,\.]*"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: (trimmed as NSString).length)) else {
            return nil
        }

        var rawStr = (trimmed as NSString).substring(with: match.range)
        rawStr = rawStr.trimmingCharacters(in: CharacterSet(charactersIn: ",."))

        if isZeroDec {
            rawStr = rawStr.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: "")
        } else {
            if rawStr.contains(",") && rawStr.contains(".") {
                if let lastComma = rawStr.lastIndex(of: ","), let lastDot = rawStr.lastIndex(of: ".") {
                    if lastDot > lastComma {
                        rawStr = rawStr.replacingOccurrences(of: ",", with: "")
                    } else {
                        rawStr = rawStr.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
                    }
                }
            } else if rawStr.contains(",") && !rawStr.contains(".") {
                let parts = rawStr.components(separatedBy: ",")
                if parts.count == 2 && parts[1].count <= 2 {
                    rawStr = parts[0] + "." + parts[1]
                } else {
                    rawStr = rawStr.replacingOccurrences(of: ",", with: "")
                }
            } else if rawStr.contains(".") && !rawStr.contains(",") {
                let parts = rawStr.components(separatedBy: ".")
                if parts.count > 2 {
                    rawStr = rawStr.replacingOccurrences(of: ".", with: "")
                }
            }
        }

        guard let amount = Double(rawStr) else { return nil }
        return (amount, detectedCurrency)
    }

    // MARK: - Timezone & Date-Line Boundary Engine

    /// Formats time in specified timezone and locale (e.g. "6:00 PM" or "18:00")
    public static func formatTime(_ date: Date, timeZone: TimeZone = .current, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        formatter.locale = locale
        return formatter.string(from: date)
    }

    /// Formats date in specified timezone and locale (e.g. "Oct 15, 2026")
    public static func formatDate(_ date: Date, timeZone: TimeZone = .current, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = timeZone
        formatter.locale = locale
        return formatter.string(from: date)
    }

    /// Calculates calendar day offset between departure and arrival in their respective local timezones.
    /// Safely handles International Date Line (IDL) crossings (e.g. Tokyo JST -> LAX PDT = 0 days; LAX PDT -> Tokyo JST = +1 day).
    public static func calculateDayOffset(from departureDate: Date, departureTimeZone: TimeZone, arrivalDate: Date, arrivalTimeZone: TimeZone) -> Int {
        var depCal = Calendar(identifier: .gregorian)
        depCal.timeZone = departureTimeZone
        let depComp = depCal.dateComponents([.year, .month, .day], from: departureDate)

        var arrCal = Calendar(identifier: .gregorian)
        arrCal.timeZone = arrivalTimeZone
        let arrComp = arrCal.dateComponents([.year, .month, .day], from: arrivalDate)

        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(secondsFromGMT: 0)!

        guard let depStart = utcCal.date(from: depComp),
              let arrStart = utcCal.date(from: arrComp) else {
            return 0
        }

        let components = utcCal.dateComponents([.day], from: depStart, to: arrStart)
        return components.day ?? 0
    }

    /// Checks if two dates fall on the exact same calendar day in their respective timezones.
    public static func areDatesInSameCalendarDay(_ date1: Date, timeZone1: TimeZone, _ date2: Date, timeZone2: TimeZone) -> Bool {
        calculateDayOffset(from: date1, departureTimeZone: timeZone1, arrivalDate: date2, arrivalTimeZone: timeZone2) == 0
    }
}
