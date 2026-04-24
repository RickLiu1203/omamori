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
    var selectedCoordinate: CLLocationCoordinate2D?

    var city: String?
    var neighborhood: String?
    var country: String?
    var fullAddress: String?
    var street: String?
    var region: String?
    var areasOfInterest: [String]?
    var placeName: String?

    var safetyResult: SafetyAssessment?

    var isLoadingLocation = false
    var isLoadingSafety = false
    var isPinSettled = true
    var isDragging = false
    var errorMessage: String?

    var isUsingCurrentLocation: Bool {
        guard let selected = selectedCoordinate, let user = userLocation else { return true }
        let selectedLocation = CLLocation(latitude: selected.latitude, longitude: selected.longitude)
        return selectedLocation.distance(from: user) < 50
    }

    var activeCoordinate: CLLocationCoordinate2D? {
        if let selected = selectedCoordinate, !isUsingCurrentLocation {
            return selected
        }
        return userLocation?.coordinate
    }

    var canCheckSafety: Bool {
        (city != nil || country != nil) && !isLoadingSafety
    }

    private let locationService = LocationService()
    private var debounceTask: Task<Void, Never>?

    func onCameraMoving() {
        isDragging = true
        isPinSettled = false
    }

    func scheduleCameraUpdate(center: CLLocationCoordinate2D) {
        debounceTask?.cancel()
        isPinSettled = false
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            isDragging = false
            isPinSettled = true
            await mapCameraDidChange(center: center)
        }
    }

    func fetchLocation() async {
        isLoadingLocation = true
        errorMessage = nil

        do {
            let location = try await locationService.requestLocation()
            userLocation = location

            let placemark = try await locationService.reverseGeocode(location)
            applyPlacemark(placemark)

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

    func returnToCurrentLocation() async {
        guard let user = userLocation else { return }
        selectedCoordinate = nil
        mapCameraPosition = .region(MKCoordinateRegion(
            center: user.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        ))
        let placemark = try? await locationService.reverseGeocode(user)
        applyPlacemark(placemark)
    }

    func mapCameraDidChange(center: CLLocationCoordinate2D) async {
        guard let user = userLocation else { return }

        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        if centerLocation.distance(from: user) < 50 {
            guard selectedCoordinate != nil else { return }
            selectedCoordinate = nil
            let placemark = try? await locationService.reverseGeocode(user)
            applyPlacemark(placemark)
            return
        }

        selectedCoordinate = center
        isLoadingLocation = true
        let placemark = try? await locationService.reverseGeocode(centerLocation)
        guard let current = selectedCoordinate,
              CLLocation(latitude: current.latitude, longitude: current.longitude)
                  .distance(from: centerLocation) < 10 else {
            isLoadingLocation = false
            return
        }
        applyPlacemark(placemark)
        isLoadingLocation = false
    }

    func checkSafety() async {
        guard let coordinate = activeCoordinate,
              let city = city,
              let country = country else { return }

        isLoadingSafety = true
        errorMessage = nil
        safetyResult = nil

        do {
            let resolvedNeighborhood = neighborhood ?? placeName ?? city
            let research = try await OpenAIService.fetchWebResearch(
                neighborhood: resolvedNeighborhood,
                city: city,
                country: country
            )
            safetyResult = try await OpenAIService.fetchSafetyAssessment(
                city: city,
                neighborhood: neighborhood,
                country: country,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                street: street,
                region: region,
                areasOfInterest: areasOfInterest,
                placeName: placeName,
                webResearch: research
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingSafety = false
    }

    private func applyPlacemark(_ placemark: CLPlacemark?) {
        city = placemark?.locality
        neighborhood = placemark?.subLocality
        country = placemark?.country
        street = [placemark?.subThoroughfare, placemark?.thoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")
        region = placemark?.administrativeArea
        areasOfInterest = placemark?.areasOfInterest
        placeName = placemark?.name
        fullAddress = [placemark?.subLocality, placemark?.locality,
                       placemark?.administrativeArea, placemark?.country]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}
