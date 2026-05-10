//
//  SafetyViewModelDisplayTests.swift
//  omamoriTests
//

import Testing
import SwiftUI
@testable import omamori

@MainActor
@Suite struct SafetyViewModelDisplayTests {

    private func makeCategory(rating: Int, headline: String = "Test headline") -> SafetyAssessment.Category {
        SafetyAssessment.Category(rating: rating, headline: headline)
    }

    private func makeSafetyCategories(rating: Int) -> SafetyAssessment.SafetyCategories {
        let cat = makeCategory(rating: rating)
        return .init(pettyTheft: cat, robbery: cat, assault: cat, sexualHarassment: cat,
                     hateCrime: cat, scamsAndFraud: cat, nightSafety: cat, streetSafety: cat,
                     transportationSafety: cat)
    }

    private func makeLiveabilityCategories(rating: Int) -> SafetyAssessment.LiveabilityCategories {
        let cat = makeCategory(rating: rating)
        return .init(walkability: cat, transitAccess: cat, climateIndex: cat,
                     pollution: cat, costOfLiving: cat, healthcare: cat)
    }

    private func makeWarnings(rating: Int) -> SafetyAssessment.Warnings {
        let cat = makeCategory(rating: rating)
        return .init(soloTravel: cat, femaleTravel: cat, lgbtqTravel: cat)
    }

    private func makeAssessment(safetyRating: Int, liveabilityRating: Int = 7) -> SafetyAssessment {
        SafetyAssessment(
            neighborhood: "Test",
            safetyTopRisks: ["Risk 1", "Risk 2"],
            liveabilityHighlights: ["Highlight 1", "Highlight 2"],
            naturalDisasterConcerns: ["earthquake zone"],
            safetyCategories: makeSafetyCategories(rating: safetyRating),
            liveabilityCategories: makeLiveabilityCategories(rating: liveabilityRating),
            warnings: makeWarnings(rating: safetyRating)
        )
    }

    // MARK: - Score Color (Safety mode)

    @Test func scoreColorGreenAboveEight() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 9)
        vm.selectedMode = .safety
        #expect(vm.scoreColor == .green)
    }

    @Test func scoreColorYellowSixToEight() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 7)
        vm.selectedMode = .safety
        #expect(vm.scoreColor == .yellow)
    }

    @Test func scoreColorOrangeFourToSix() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 5)
        vm.selectedMode = .safety
        #expect(vm.scoreColor == .orange)
    }

    @Test func scoreColorRedBelowFour() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 3)
        vm.selectedMode = .safety
        #expect(vm.scoreColor == .red)
    }

    @Test func scoreFractionUsesSafetyScoreInSafetyMode() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 8, liveabilityRating: 4)
        vm.selectedMode = .safety
        #expect(abs(vm.scoreFraction - 0.8) < 0.001)
    }

    @Test func scoreFractionUsesLiveabilityScoreInLiveabilityMode() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 8, liveabilityRating: 6)
        vm.selectedMode = .liveability
        #expect(abs(vm.scoreFraction - 0.6) < 0.001)
    }

    // MARK: - Current Categories

    @Test func currentCategoriesReturnsSafetyInSafetyMode() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 7)
        vm.selectedMode = .safety
        let categories = vm.currentCategories
        #expect(categories.count == 9)
        #expect(categories[0].id == "scamsAndFraud")
    }

    @Test func currentCategoriesReturnsLiveabilityInLiveabilityMode() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 7)
        vm.selectedMode = .liveability
        let categories = vm.currentCategories
        #expect(categories.count == 6)
        #expect(categories[0].id == "costOfLiving")
    }

    // MARK: - Current Top Risks

    @Test func currentTopRisksReturnsSafetyRisksInSafetyMode() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 7)
        vm.selectedMode = .safety
        #expect(vm.currentTopRisks == ["Risk 1", "Risk 2"])
    }

    @Test func currentTopRisksReturnsHighlightsInLiveabilityMode() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 7)
        vm.selectedMode = .liveability
        #expect(vm.currentTopRisks == ["Highlight 1", "Highlight 2"])
    }

    // MARK: - Active Warnings (safety-only)

    @Test func activeWarningsExcludesAboveThreshold() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 6) // warnings all 6 > threshold 5
        vm.selectedMode = .safety
        #expect(vm.activeWarnings.isEmpty)
    }

    @Test func activeWarningsIncludesBelowOrAtThreshold() {
        let vm = SafetyViewModel()
        let warnCat = makeCategory(rating: 4, headline: "Solo risk noted")
        let safeCat = makeCategory(rating: 8)
        let lowSafety = makeCategory(rating: 7)
        vm.safetyResult = SafetyAssessment(
            neighborhood: "Test",
            safetyTopRisks: ["R1", "R2"],
            liveabilityHighlights: ["H1", "H2"],
            naturalDisasterConcerns: [],
            safetyCategories: makeSafetyCategories(rating: 7),
            liveabilityCategories: makeLiveabilityCategories(rating: 7),
            warnings: .init(soloTravel: warnCat, femaleTravel: safeCat, lgbtqTravel: safeCat)
        )
        vm.selectedMode = .safety
        let warnings = vm.activeWarnings
        #expect(warnings.count == 1)
        #expect(warnings[0].id == "soloTravel")
    }

    @Test func activeWarningsEmptyInLiveabilityMode() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 3) // warnings all 3, would trigger in safety
        vm.selectedMode = .liveability
        #expect(vm.activeWarnings.isEmpty)
    }

    // MARK: - Natural Disaster Concerns

    @Test func naturalDisasterConcernsExposedFromResult() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(safetyRating: 7)
        #expect(vm.naturalDisasterConcerns == ["earthquake zone"])
    }
}
