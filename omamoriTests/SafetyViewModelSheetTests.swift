//
//  SafetyViewModelSheetTests.swift
//  omamoriTests
//

import Testing
import CoreLocation
@testable import omamori

@MainActor
@Suite struct SafetyViewModelSheetTests {

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

    @Test func isResultsSheetPresentedFalseInitially() {
        let vm = SafetyViewModel()
        #expect(vm.isResultsSheetPresented == false)
    }

    @Test func requestSafetyCheckPresentsSheetWhenResultReusable() async {
        let vm = SafetyViewModel()
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        vm.userLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        vm.safetyResult = makeAssessment()
        vm.lastAssessedCoordinate = coord
        vm.city = "San Francisco"
        vm.country = "United States"

        await vm.requestSafetyCheck()

        #expect(vm.isResultsSheetPresented == true)
    }
}
