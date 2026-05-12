//
//  DisplayItemTests.swift
//  omamoriTests
//

import Testing
@testable import omamori

@MainActor
@Suite struct DisplayItemTests {

    private func makeCategory(rating: Int = 7) -> SafetyAssessment.Category {
        SafetyAssessment.Category(rating: rating, headline: "Test headline")
    }

    private func makeAssessment(withDisasters: [String] = []) -> SafetyAssessment {
        let cat = makeCategory()
        return SafetyAssessment(
            neighborhood: "Test",
            safetyTopRisks: ["R1", "R2"],
            liveabilityHighlights: ["H1", "H2"],
            naturalDisasterConcerns: withDisasters,
            safetyCategories: .init(pettyTheft: cat, robbery: cat, assault: cat,
                                    sexualHarassment: cat, hateCrime: cat, scamsAndFraud: cat,
                                    nightSafety: cat, streetSafety: cat, transportationSafety: cat),
            liveabilityCategories: .init(walkability: cat, transitAccess: cat, climateIndex: cat,
                                         pollution: cat, costOfLiving: cat, healthcare: cat),
            warnings: .init(soloTravel: cat, femaleTravel: cat, lgbtqTravel: cat)
        )
    }

    // MARK: - Safety categories

    @Test func safetyCategoriesCountIsNine() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment()
        vm.selectedMode = .safety
        #expect(vm.currentCategories.count == 9)
    }

    @Test func safetyCategoriesHaveNonEmptyIcons() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment()
        vm.selectedMode = .safety
        #expect(vm.currentCategories.allSatisfy { !$0.icon.isEmpty })
    }

    @Test func safetyCategoriesHaveNonEmptyHeadlines() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment()
        vm.selectedMode = .safety
        #expect(vm.currentCategories.allSatisfy { !$0.headline.isEmpty })
    }

    // MARK: - Liveability categories

    @Test func liveabilityCategoriesCountIsSix() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment()
        vm.selectedMode = .liveability
        #expect(vm.currentCategories.count == 6)
    }

    @Test func liveabilityCategoriesHaveNonEmptyIcons() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment()
        vm.selectedMode = .liveability
        #expect(vm.currentCategories.allSatisfy { !$0.icon.isEmpty })
    }

    // MARK: - Warnings

    @Test func warningItemRatingMatchesSource() {
        let vm = SafetyViewModel()
        let warnCat = SafetyAssessment.Category(rating: 3, headline: "High risk")
        let safeCat = makeCategory(rating: 8)
        vm.safetyResult = SafetyAssessment(
            neighborhood: "Test",
            safetyTopRisks: ["R1"],
            liveabilityHighlights: ["H1"],
            naturalDisasterConcerns: [],
            safetyCategories: .init(pettyTheft: safeCat, robbery: safeCat, assault: safeCat,
                                    sexualHarassment: safeCat, hateCrime: safeCat, scamsAndFraud: safeCat,
                                    nightSafety: safeCat, streetSafety: safeCat, transportationSafety: safeCat),
            liveabilityCategories: .init(walkability: safeCat, transitAccess: safeCat, climateIndex: safeCat,
                                         pollution: safeCat, costOfLiving: safeCat, healthcare: safeCat),
            warnings: .init(soloTravel: warnCat, femaleTravel: safeCat, lgbtqTravel: safeCat)
        )
        vm.selectedMode = .safety
        let warnings = vm.activeWarnings
        #expect(warnings.count == 1)
        #expect(warnings[0].rating == 3)
    }

    // MARK: - Natural disaster concerns

    @Test func naturalDisasterConcernsExposedWhenPresent() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(withDisasters: ["earthquake zone", "seasonal flooding"])
        #expect(vm.naturalDisasterConcerns.count == 2)
        #expect(vm.naturalDisasterConcerns.contains("earthquake zone"))
    }

    @Test func naturalDisasterConcernsEmptyWhenNone() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(withDisasters: [])
        #expect(vm.naturalDisasterConcerns.isEmpty)
    }
}
