//
//  SafetyViewModelModeTests.swift
//  omamoriTests
//

import Testing
import Foundation
@testable import omamori

@MainActor
@Suite struct SafetyViewModelModeTests {

    private static let testKey = "selectedMode"

    private func makeCategory(rating: Int = 7) -> SafetyAssessment.Category {
        SafetyAssessment.Category(rating: rating, headline: "Test headline")
    }

    private func makeAssessment() -> SafetyAssessment {
        let cat = makeCategory()
        return SafetyAssessment(
            neighborhood: "Test",
            safetyTopRisks: ["R1", "R2"],
            liveabilityHighlights: ["H1", "H2"],
            naturalDisasterConcerns: [],
            safetyCategories: .init(pettyTheft: cat, robbery: cat, assault: cat,
                                    sexualHarassment: cat, hateCrime: cat, scamsAndFraud: cat,
                                    nightSafety: cat, streetSafety: cat, transportationSafety: cat),
            liveabilityCategories: .init(walkability: cat, transitAccess: cat, climateIndex: cat,
                                         pollution: cat, costOfLiving: cat, healthcare: cat),
            warnings: .init(soloTravel: cat, femaleTravel: cat, lgbtqTravel: cat)
        )
    }

    @Test func selectedModePersistsToUserDefaults() {
        UserDefaults.standard.removeObject(forKey: Self.testKey)
        defer { UserDefaults.standard.removeObject(forKey: Self.testKey) }

        let vm = SafetyViewModel()
        vm.selectedMode = .liveability

        let vm2 = SafetyViewModel()
        #expect(vm2.selectedMode == .liveability)
    }

    @Test func loadingPhaseIsNilInitially() {
        let vm = SafetyViewModel()
        #expect(vm.loadingPhase == nil)
    }

    @Test func currentCategoriesReactToModeChange() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment()

        vm.selectedMode = .safety
        #expect(vm.currentCategories.count == 9)
        #expect(vm.currentCategories.first?.id == "scamsAndFraud")

        vm.selectedMode = .liveability
        #expect(vm.currentCategories.count == 6)
        #expect(vm.currentCategories.first?.id == "costOfLiving")

        vm.selectedMode = .safety
        #expect(vm.currentCategories.count == 9)
    }
}
