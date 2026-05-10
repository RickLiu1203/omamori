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
    var selectedMode: SafetyMode = .tourist

    var isLoadingLocation = false
    var isLoadingSafety = false
    var isPinSettled = true
    var isDragging = false
    var errorMessage: String?

    var lastAssessedCoordinate: CLLocationCoordinate2D?
    var isResultsSheetPresented = false

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

    var canReuseResult: Bool {
        guard safetyResult != nil,
              let last = lastAssessedCoordinate,
              let active = activeCoordinate else { return false }
        let lastLoc = CLLocation(latitude: last.latitude, longitude: last.longitude)
        let activeLoc = CLLocation(latitude: active.latitude, longitude: active.longitude)
        return activeLoc.distance(from: lastLoc) < 50
    }

    var scoreColor: Color {
        let rating = safetyResult?.overallRating ?? 0
        switch rating {
        case 8...: return .green
        case 6..<8: return .yellow
        case 4..<6: return .orange
        default: return .red
        }
    }

    var scoreFraction: Double {
        (safetyResult?.overallRating ?? 0) / 10.0
    }

    var sheetHeaderTitle: String {
        guard let n = safetyResult?.neighborhood else { return "" }
        if let c = city { return "\(n) · \(c)" }
        return n
    }

    var currentTopRisks: [String] {
        guard let result = safetyResult else { return [] }
        return selectedMode == .tourist ? result.touristTopRisks : result.residentTopRisks
    }

    var currentCategories: [CategoryDisplayItem] {
        guard let sub = safetyResult?.subcategories else { return [] }

        let all: [(id: String, icon: String, name: String, cat: SafetyAssessment.Category)] = [
            ("pettyTheft",          "bag.fill",                                      "Petty Theft",         sub.pettyTheft),
            ("robbery",             "hand.raised.fill",                              "Robbery",             sub.robbery),
            ("assault",             "figure.boxing",                                 "Assault",             sub.assault),
            ("sexualHarassment",    "exclamationmark.bubble.fill",                   "Sexual Harassment",   sub.sexualHarassment),
            ("hateCrime",           "person.fill.xmark",                             "Hate Crime",          sub.hateCrime),
            ("scamsAndFraud",       "creditcard.trianglebadge.exclamationmark.fill", "Scams & Fraud",       sub.scamsAndFraud),
            ("nightSafety",         "moon.fill",                                     "Night Safety",        sub.nightSafety),
            ("streetSafety",        "road.lanes",                                    "Street Safety",       sub.streetSafety),
            ("transportationSafety","bus.fill",                                      "Transportation",      sub.transportationSafety)
        ]

        let touristOrder = ["scamsAndFraud", "nightSafety", "transportationSafety", "pettyTheft",
                            "robbery", "assault", "sexualHarassment", "hateCrime", "streetSafety"]
        let residentOrder = ["streetSafety", "assault", "nightSafety", "robbery", "pettyTheft",
                             "sexualHarassment", "hateCrime", "scamsAndFraud", "transportationSafety"]

        let order = selectedMode == .tourist ? touristOrder : residentOrder
        let dict = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

        return order.compactMap { id in
            guard let item = dict[id] else { return nil }
            let headline = selectedMode == .tourist ? item.cat.touristHeadline : item.cat.residentHeadline
            return CategoryDisplayItem(id: item.id, icon: item.icon, name: item.name, rating: item.cat.rating, headline: headline)
        }
    }

    var activeWarnings: [WarningDisplayItem] {
        guard let result = safetyResult else { return [] }
        let threshold = SafetyAssessment.warningThreshold
        let w = result.warnings

        let candidates: [(id: String, icon: String, name: String, cat: SafetyAssessment.Category)] = [
            ("soloTravel",   "figure.walk",                        "Solo Travel",   w.soloTravel),
            ("femaleTravel", "figure.dress.line.vertical.figure",  "Female Travel", w.femaleTravel),
            ("lgbtqTravel",  "rainbow",                            "LGBTQ+ Travel", w.lgbtqTravel)
        ]

        return candidates.compactMap { item in
            guard item.cat.rating <= threshold else { return nil }
            let headline = selectedMode == .tourist ? item.cat.touristHeadline : item.cat.residentHeadline
            return WarningDisplayItem(id: item.id, icon: item.icon, name: item.name, rating: item.cat.rating, headline: headline)
        }
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
        safetyResult = nil
        isResultsSheetPresented = false
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

    func requestSafetyCheck() async {
        if canReuseResult {
            isResultsSheetPresented = true
        } else {
            await checkSafety()
            if safetyResult != nil {
                isResultsSheetPresented = true
            }
        }
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
            lastAssessedCoordinate = activeCoordinate
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
