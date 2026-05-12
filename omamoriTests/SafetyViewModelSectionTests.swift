//
//  SafetyViewModelSectionTests.swift
//  omamoriTests
//

import Testing
@testable import omamori

@MainActor
@Suite struct SafetyViewModelSectionTests {

    private func makeCategory(rating: Int = 7) -> SafetyAssessment.Category {
        SafetyAssessment.Category(rating: rating, headline: "Test headline")
    }

    private func makeAssessment(safetyRating: Int = 7) -> SafetyAssessment {
        let cat = makeCategory(rating: safetyRating)
        let safe = makeCategory(rating: 8)
        return SafetyAssessment(
            neighborhood: "Alfama",
            safetyTopRisks: ["Risk 1", "Risk 2"],
            liveabilityHighlights: ["Highlight 1", "Highlight 2"],
            naturalDisasterConcerns: [],
            safetyCategories: .init(pettyTheft: cat, robbery: cat, assault: cat,
                                    sexualHarassment: cat, hateCrime: cat, scamsAndFraud: cat,
                                    nightSafety: cat, streetSafety: cat, transportationSafety: cat),
            liveabilityCategories: .init(walkability: safe, transitAccess: safe, climateIndex: safe,
                                         pollution: safe, costOfLiving: safe, healthcare: safe),
            warnings: .init(soloTravel: cat, femaleTravel: cat, lgbtqTravel: cat)
        )
    }

    // MARK: - Top risks / highlights

    @Test func safetyTopRisksCountIsTwo() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment()
        vm.selectedMode = .safety
        #expect(vm.currentTopRisks.count == 2)
    }

    @Test func liveabilityHighlightsCountIsTwo() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment()
        vm.selectedMode = .liveability
        #expect(vm.currentTopRisks.count == 2)
    }

    // MARK: - Category order

    @Test func safetyCategoryOrderMatchesSpec() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment()
        vm.selectedMode = .safety
        let ids = vm.currentCategories.map(\.id)
        #expect(ids.first == "scamsAndFraud")
        #expect(ids.last == "streetSafety")
    }

    @Test func liveabilityCategoryOrderMatchesSpec() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment()
        vm.selectedMode = .liveability
        let ids = vm.currentCategories.map(\.id)
        #expect(ids.first == "costOfLiving")
        #expect(ids.last == "climateIndex")
    }

    // MARK: - Active warnings

    @Test func activeWarningsEmptyWhenAllAboveThreshold() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 6) // 6 > threshold 5
        vm.selectedMode = .safety
        #expect(vm.activeWarnings.isEmpty)
    }

    @Test func activeWarningsEmptyInLiveabilityMode() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 3) // would trigger in safety
        vm.selectedMode = .liveability
        #expect(vm.activeWarnings.isEmpty)
    }

    @Test func activeWarningsPopulatedWhenAnyAtOrBelowThreshold() {
        let vm = SafetyViewModel()
        let warnCat = SafetyAssessment.Category(rating: 5, headline: "At threshold")
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
        #expect(vm.activeWarnings.count == 1)
        #expect(vm.activeWarnings[0].id == "soloTravel")
    }

    // MARK: - Sheet header title

    @Test func sheetHeaderTitleFormatsNeighborhoodAndCity() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment()
        vm.city = "Lisbon"
        #expect(vm.sheetHeaderTitle == "Alfama · Lisbon")
    }

    @Test func sheetHeaderTitleFallsBackWhenNoCityName() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment()
        vm.city = nil
        #expect(vm.sheetHeaderTitle == "Alfama")
    }

    // MARK: - currentTopRisksTitle

    @Test func currentTopRisksTitleIsSafetyRisksInSafetyMode() {
        let vm = SafetyViewModel()
        vm.selectedMode = .safety
        #expect(vm.currentTopRisksTitle == "Top Safety Risks")
    }

    @Test func currentTopRisksTitleIsKeyHighlightsInLiveabilityMode() {
        let vm = SafetyViewModel()
        vm.selectedMode = .liveability
        #expect(vm.currentTopRisksTitle == "Key Highlights")
    }

    // MARK: - scoreLabel

    @Test func scoreLabelIsSafetyScoreInSafetyMode() {
        let vm = SafetyViewModel()
        vm.selectedMode = .safety
        #expect(vm.scoreLabel == "Safety Score")
    }

    @Test func scoreLabelIsLiveabilityScoreInLiveabilityMode() {
        let vm = SafetyViewModel()
        vm.selectedMode = .liveability
        #expect(vm.scoreLabel == "Liveability Score")
    }
}
