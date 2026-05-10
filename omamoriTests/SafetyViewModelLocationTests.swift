//
//  SafetyViewModelLocationTests.swift
//  omamoriTests
//

import Testing
import CoreLocation
@testable import omamori

@MainActor
@Suite struct SafetyViewModelLocationTests {

    private func makeCategory(rating: Int = 7) -> SafetyAssessment.Category {
        SafetyAssessment.Category(rating: rating, headline: "Test")
    }

    private func makeAssessment() -> SafetyAssessment {
        let cat = makeCategory()
        return SafetyAssessment(
            neighborhood: "Test",
            safetyTopRisks: ["R1"],
            liveabilityHighlights: ["H1"],
            naturalDisasterConcerns: [],
            safetyCategories: .init(pettyTheft: cat, robbery: cat, assault: cat,
                                    sexualHarassment: cat, hateCrime: cat, scamsAndFraud: cat,
                                    nightSafety: cat, streetSafety: cat, transportationSafety: cat),
            liveabilityCategories: .init(walkability: cat, transitAccess: cat, climateIndex: cat,
                                         pollution: cat, costOfLiving: cat, healthcare: cat),
            warnings: .init(soloTravel: cat, femaleTravel: cat, lgbtqTravel: cat)
        )
    }

    @Test func returnToCurrentLocationClearsSelectedCoordinate() async {
        let vm = SafetyViewModel()
        vm.userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        vm.selectedCoordinate = CLLocationCoordinate2D(latitude: 37.8, longitude: -122.5)

        await vm.returnToCurrentLocation()

        #expect(vm.selectedCoordinate == nil)
    }

    @Test func returnToCurrentLocationClearsSafetyResult() async {
        let vm = SafetyViewModel()
        vm.userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        vm.safetyResult = makeAssessment()

        await vm.returnToCurrentLocation()

        #expect(vm.safetyResult == nil)
    }

    @Test func returnToCurrentLocationHidesSheet() async {
        let vm = SafetyViewModel()
        vm.userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        vm.isResultsSheetPresented = true

        await vm.returnToCurrentLocation()

        #expect(vm.isResultsSheetPresented == false)
    }

    @Test func canReuseResultFalseWithNoResult() {
        let vm = SafetyViewModel()
        vm.userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        vm.lastAssessedCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

        #expect(vm.canReuseResult == false)
    }

    @Test func canReuseResultFalseWhenPinMovedBeyond50m() {
        let vm = SafetyViewModel()
        vm.userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        vm.safetyResult = makeAssessment()
        // ~1km away from lastAssessed
        vm.lastAssessedCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        vm.selectedCoordinate = CLLocationCoordinate2D(latitude: 37.784, longitude: -122.4194)

        #expect(vm.canReuseResult == false)
    }

    @Test func canReuseResultTrueWhenPinWithin50m() {
        let vm = SafetyViewModel()
        vm.userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        vm.safetyResult = makeAssessment()
        let base = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        vm.lastAssessedCoordinate = base
        // ~10m offset — well within 50m
        vm.selectedCoordinate = CLLocationCoordinate2D(latitude: 37.77491, longitude: -122.41941)

        #expect(vm.canReuseResult == true)
    }
}
