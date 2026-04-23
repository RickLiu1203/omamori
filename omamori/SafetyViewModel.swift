//
//  SafetyViewModel.swift
//  omamori
//
//  Created by RickLiu1203 on 2026-04-23.
//

import SwiftUI
import CoreLocation
import MapKit

@MainActor
@Observable
final class SafetyViewModel {

    var userLocation: CLLocation?
    var mapCameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var city: String?
    var neighborhood: String?
    var country: String?
    var fullAddress: String?

    var safetyResult: String?

    var isLoadingLocation = false
    var isLoadingSafety = false
    var errorMessage: String?

    var canCheckSafety: Bool {
        (city != nil || country != nil) && !isLoadingSafety
    }

    private let locationManager = LocationManager()

    func fetchLocation() async {
        isLoadingLocation = true
        errorMessage = nil

        do {
            let location = try await locationManager.requestLocation()
            userLocation = location

            let placemark = try await locationManager.reverseGeocode(location)
            city = placemark.locality
            neighborhood = placemark.subLocality
            country = placemark.country
            fullAddress = [placemark.subLocality, placemark.locality,
                           placemark.administrativeArea, placemark.country]
                .compactMap { $0 }
                .joined(separator: ", ")

            mapCameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            ))
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingLocation = false
    }

    func checkSafety() async {
        guard let location = userLocation,
              let city = city,
              let country = country else { return }

        isLoadingSafety = true
        errorMessage = nil
        safetyResult = nil

        do {
            safetyResult = try await OpenAIService.fetchSafetyAssessment(
                city: city,
                neighborhood: neighborhood,
                country: country,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingSafety = false
    }
}
