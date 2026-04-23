//
//  LocationService.swift
//  omamori
//
//  Created by RickLiu1203 on 2026-04-23.
//

import CoreLocation

enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable
    case reverseGeocodeFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission was denied. Please enable it in Settings."
        case .locationUnavailable:
            return "Unable to determine your location."
        case .reverseGeocodeFailed:
            return "Unable to determine address for your location."
        }
    }
}

@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authContinuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() async throws -> CLLocation {
        try await ensureAuthorized()

        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
        }
    }

    func reverseGeocode(_ location: CLLocation) async throws -> CLPlacemark {
        let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else {
            throw LocationError.reverseGeocodeFailed
        }
        return placemark
    }

    private func ensureAuthorized() async throws {
        switch manager.authorizationStatus {
        case .notDetermined:
            await withCheckedContinuation { continuation in
                self.authContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
            if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
                throw LocationError.permissionDenied
            }
        case .denied, .restricted:
            throw LocationError.permissionDenied
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            break
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: error)
            locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authContinuation?.resume()
            authContinuation = nil
        }
    }
}
