//
//  SafetyViewModelDisplayTests.swift
//  omamoriTests
//

import Testing
import SwiftUI
@testable import omamori

@MainActor
@Suite struct SafetyViewModelDisplayTests {

    private func makeCategory(
        rating: Int,
        touristHeadline: String = "Tourist headline here",
        residentHeadline: String = "Resident headline here"
    ) -> SafetyAssessment.Category {
        SafetyAssessment.Category(rating: rating, touristHeadline: touristHeadline, residentHeadline: residentHeadline)
    }

    private func makeAssessment(allRatings: Int) -> SafetyAssessment {
        let cat = makeCategory(rating: allRatings)
        return SafetyAssessment(
            neighborhood: "Test",
            touristTopRisks: ["Risk one", "Risk two"],
            residentTopRisks: ["Risk alpha", "Risk beta"],
            subcategories: .init(
                pettyTheft: cat, robbery: cat, assault: cat,
                sexualHarassment: cat, hateCrime: cat, scamsAndFraud: cat,
                nightSafety: cat, streetSafety: cat, transportationSafety: cat
            ),
            warnings: .init(soloTravel: cat, femaleTravel: cat, lgbtqTravel: cat)
        )
    }

    private func makeAssessmentWithDistinctHeadlines() -> SafetyAssessment {
        let cat = makeCategory(rating: 7, touristHeadline: "TOURIST_HEADLINE", residentHeadline: "RESIDENT_HEADLINE")
        return SafetyAssessment(
            neighborhood: "Test",
            touristTopRisks: ["Tourist risk one", "Tourist risk two"],
            residentTopRisks: ["Resident risk one", "Resident risk two"],
            subcategories: .init(
                pettyTheft: cat, robbery: cat, assault: cat,
                sexualHarassment: cat, hateCrime: cat, scamsAndFraud: cat,
                nightSafety: cat, streetSafety: cat, transportationSafety: cat
            ),
            warnings: .init(soloTravel: cat, femaleTravel: cat, lgbtqTravel: cat)
        )
    }

    // MARK: - Score Color

    @Test func scoreColorGreenAboveEight() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(allRatings: 9) // overallRating = 9.0
        #expect(vm.scoreColor == .green)
    }

    @Test func scoreColorYellowSixToEight() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(allRatings: 7) // overallRating = 7.0
        #expect(vm.scoreColor == .yellow)
    }

    @Test func scoreColorOrangeFourToSix() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(allRatings: 5) // overallRating = 5.0
        #expect(vm.scoreColor == .orange)
    }

    @Test func scoreColorRedBelowFour() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(allRatings: 3) // overallRating = 3.0
        #expect(vm.scoreColor == .red)
    }

    @Test func scoreFractionDividesBy10() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessment(allRatings: 8) // overallRating = 8.0
        #expect(abs(vm.scoreFraction - 0.8) < 0.001)
    }

    // MARK: - Current Categories

    @Test func currentCategoriesUsesTouristOrderAndHeadline() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessmentWithDistinctHeadlines()
        vm.selectedMode = .tourist
        let categories = vm.currentCategories
        #expect(categories.count == 9)
        #expect(categories[0].id == "scamsAndFraud") // first in tourist order
        #expect(categories[0].headline == "TOURIST_HEADLINE")
    }

    @Test func currentCategoriesUsesResidentOrderAndHeadline() {
        let vm = SafetyViewModel()
        vm.safetyResult = makeAssessmentWithDistinctHeadlines()
        vm.selectedMode = .resident
        let categories = vm.currentCategories
        #expect(categories.count == 9)
        #expect(categories[0].id == "streetSafety") // first in resident order
        #expect(categories[0].headline == "RESIDENT_HEADLINE")
    }

    // MARK: - Active Warnings

    @Test func activeWarningsExcludesAboveThreshold() {
        let vm = SafetyViewModel()
        // All warnings at 6, above warningThreshold (5) — none should appear
        let highCat = makeCategory(rating: 6)
        let lowCat = makeCategory(rating: 7)
        vm.safetyResult = SafetyAssessment(
            neighborhood: "Test",
            touristTopRisks: ["R1", "R2"],
            residentTopRisks: ["R1", "R2"],
            subcategories: .init(
                pettyTheft: lowCat, robbery: lowCat, assault: lowCat,
                sexualHarassment: lowCat, hateCrime: lowCat, scamsAndFraud: lowCat,
                nightSafety: lowCat, streetSafety: lowCat, transportationSafety: lowCat
            ),
            warnings: .init(soloTravel: highCat, femaleTravel: highCat, lgbtqTravel: highCat)
        )
        #expect(vm.activeWarnings.isEmpty)
    }

    @Test func activeWarningsIncludesBelowOrAtThreshold() {
        let vm = SafetyViewModel()
        // soloTravel at 4 (≤ warningThreshold of 5), others above
        let warnCat = makeCategory(rating: 4, touristHeadline: "Solo risk noted", residentHeadline: "Solo risk res")
        let safeCat = makeCategory(rating: 8)
        let lowCat = makeCategory(rating: 7)
        vm.safetyResult = SafetyAssessment(
            neighborhood: "Test",
            touristTopRisks: ["R1", "R2"],
            residentTopRisks: ["R1", "R2"],
            subcategories: .init(
                pettyTheft: lowCat, robbery: lowCat, assault: lowCat,
                sexualHarassment: lowCat, hateCrime: lowCat, scamsAndFraud: lowCat,
                nightSafety: lowCat, streetSafety: lowCat, transportationSafety: lowCat
            ),
            warnings: .init(soloTravel: warnCat, femaleTravel: safeCat, lgbtqTravel: safeCat)
        )
        vm.selectedMode = .tourist
        let warnings = vm.activeWarnings
        #expect(warnings.count == 1)
        #expect(warnings[0].id == "soloTravel")
        #expect(warnings[0].headline == "Solo risk noted")
    }
}
