//
//  NetworkService.swift
//  WayPoint
//
//  Module 4: Live Network Client with Offline Fallback (URLSession)
//

import Foundation

public struct LiveWeatherReport: Codable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let precipitationMm: Double
    public let weatherCode: Int
    public let isSevereWeather: Bool
    public let conditionDescription: String
}

public final class NetworkService {
    public static let shared = NetworkService()

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5.0
        configuration.timeoutIntervalForResource = 5.0
        configuration.waitsForConnectivity = false
        self.session = URLSession(configuration: configuration)
    }

    /// Fetches live weather condition for coordinates. If unconfigured or offline, falls back seamlessly to baseline without error modals.
    public func fetchWeather(latitude: Double, longitude: Double) async -> LiveWeatherReport {
        guard AppConfig.shared.isLiveWeatherConfigured else {
            return fallbackBaselineWeather(lat: latitude, lon: longitude)
        }

        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current_weather=true"
        guard let url = URL(string: urlString) else {
            return fallbackBaselineWeather(lat: latitude, lon: longitude)
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return fallbackBaselineWeather(lat: latitude, lon: longitude)
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let currentWeather = json?["current_weather"] as? [String: Any]
            let weatherCode = currentWeather?["weathercode"] as? Int ?? 0

            let isSevere = weatherCode >= 50 // Precipitation / Storm code threshold
            let condition = weatherCodeToDescription(weatherCode)

            return LiveWeatherReport(
                latitude: latitude,
                longitude: longitude,
                precipitationMm: isSevere ? 15.0 : 0.0,
                weatherCode: weatherCode,
                isSevereWeather: isSevere,
                conditionDescription: condition
            )
        } catch {
            print("[NetworkService] Weather endpoint unreachable or timed out (\(error.localizedDescription)). Falling back seamlessly to local baseline.")
            return fallbackBaselineWeather(lat: latitude, lon: longitude)
        }
    }

    /// Baseline fallback when offline, in Airplane mode, or unconfigured
    private func fallbackBaselineWeather(lat: Double, lon: Double) -> LiveWeatherReport {
        return LiveWeatherReport(
            latitude: lat,
            longitude: lon,
            precipitationMm: 0.0,
            weatherCode: 0,
            isSevereWeather: false,
            conditionDescription: "Clear (Local Baseline)"
        )
    }

    private func weatherCodeToDescription(_ code: Int) -> String {
        switch code {
        case 0: return "Clear Sky"
        case 1, 2, 3: return "Partly Cloudy"
        case 45, 48: return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65: return "Rain"
        case 80, 81, 82: return "Heavy Rain Shower"
        case 95, 96, 99: return "Thunderstorm"
        default: return "Cloudy"
        }
    }
}
