//
//  LocationService.swift
//  WayPoint
//

import Foundation
import CoreLocation
import SwiftUI

typealias LocationManager = LocationService

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    var currentLocation: CLLocation? = nil
    var currentCityCountry: String = "Detecting location..."
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var isGeocoding = false
    private var geocodeCache: [String: String] = [:]
    private var lastGeocodedLocation: CLLocation? = nil

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
    }

    func requestLocationPermission() {
        authorizationStatus = locationManager.authorizationStatus
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            print("[LocationService] Location access restricted or denied. Using fallback location.")
        @unknown default:
            break
        }
    }

    /// Null Island & Range Coordinate Guard
    static func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        return latitude != 0.0 && longitude != 0.0 && abs(latitude) <= 90.0 && abs(longitude) <= 180.0
    }

    /// Safely calculates distance in meters between user location and target coordinates with zero fallback on invalid inputs
    func distanceMeters(to latitude: Double, to longitude: Double) -> Int {
        guard Self.isValidCoordinate(latitude: latitude, longitude: longitude),
              let userLoc = currentLocation else {
            return 0
        }
        let venueLoc = CLLocation(latitude: latitude, longitude: longitude)
        let meters = userLoc.distance(from: venueLoc)
        return max(50, Int(meters))
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            switch self.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .restricted, .denied:
                print("[LocationService] Authorization changed to restricted/denied.")
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            self.reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService Error: \(error.localizedDescription)")
    }

    private func reverseGeocode(_ location: CLLocation) {
        let cacheKey = String(format: "%.4f,%.4f", location.coordinate.latitude, location.coordinate.longitude)
        if let cached = geocodeCache[cacheKey] {
            self.currentCityCountry = cached
            return
        }

        if let lastLoc = lastGeocodedLocation, location.distance(from: lastLoc) < 100 {
            return
        }

        guard !isGeocoding else { return }
        isGeocoding = true
        lastGeocodedLocation = location

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.isGeocoding = false

                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.name
                    let country = placemark.country
                    var resultStr = ""
                    if let city = city, let country = country {
                        resultStr = "\(city), \(country)"
                    } else if let city = city {
                        resultStr = city
                    } else if let country = country {
                        resultStr = country
                    }
                    if !resultStr.isEmpty {
                        self.currentCityCountry = resultStr
                        self.geocodeCache[cacheKey] = resultStr
                    }
                }
            }
        }
    }
}
