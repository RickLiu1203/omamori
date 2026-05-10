//
//  SafetyAssessmentTests.swift
//  omamoriTests
//

import Testing
import Foundation
@testable import omamori

@Suite struct SafetyAssessmentDecodingTests {

    private static let fixtureJSON = """
    {
      "neighborhood": "Test District",
      "safety_top_risks": ["Pickpocket risk high", "Taxi scams common"],
      "liveability_highlights": ["Excellent transit options", "High cost of rent"],
      "natural_disaster_concerns": ["earthquake zone", "seasonal flooding"],
      "safety_categories": {
        "petty_theft":           {"rating": 3, "headline": "High pickpocket risk"},
        "robbery":               {"rating": 7, "headline": "Low robbery risk"},
        "assault":               {"rating": 8, "headline": "Rare assault incidents"},
        "sexual_harassment":     {"rating": 6, "headline": "Some harassment reported"},
        "hate_crime":            {"rating": 9, "headline": "Very few hate crimes"},
        "scams_and_fraud":       {"rating": 4, "headline": "Watch for tourist scams"},
        "night_safety":          {"rating": 5, "headline": "Risky after midnight"},
        "street_safety":         {"rating": 7, "headline": "Busy but manageable"},
        "transportation_safety": {"rating": 8, "headline": "Safe reliable transit"}
      },
      "liveability_categories": {
        "walkability":    {"rating": 8, "headline": "Most errands walkable"},
        "transit_access": {"rating": 9, "headline": "Excellent metro coverage"},
        "climate_index":  {"rating": 6, "headline": "Mild but humid summers"},
        "pollution":      {"rating": 5, "headline": "Moderate air quality"},
        "cost_of_living": {"rating": 3, "headline": "Very expensive city"},
        "healthcare":     {"rating": 9, "headline": "World-class hospitals nearby"}
      },
      "warnings": {
        "solo_travel":   {"rating": 7, "headline": "Generally safe solo"},
        "female_travel": {"rating": 5, "headline": "Some harassment risk"},
        "lgbtq_travel":  {"rating": 9, "headline": "Welcoming open community"}
      }
    }
    """

    private func decode() throws -> SafetyAssessment {
        let data = Self.fixtureJSON.data(using: .utf8)!
        return try JSONDecoder().decode(SafetyAssessment.self, from: data)
    }

    @Test func decodesNineSafetyCategories() throws {
        let result = try decode()
        let sub = result.safetyCategories
        #expect(sub.pettyTheft.rating == 3)
        #expect(sub.robbery.rating == 7)
        #expect(sub.assault.rating == 8)
        #expect(sub.sexualHarassment.rating == 6)
        #expect(sub.hateCrime.rating == 9)
        #expect(sub.scamsAndFraud.rating == 4)
        #expect(sub.nightSafety.rating == 5)
        #expect(sub.streetSafety.rating == 7)
        #expect(sub.transportationSafety.rating == 8)
    }

    @Test func decodesSixLiveabilityCategories() throws {
        let result = try decode()
        let live = result.liveabilityCategories
        #expect(live.walkability.rating == 8)
        #expect(live.transitAccess.rating == 9)
        #expect(live.climateIndex.rating == 6)
        #expect(live.pollution.rating == 5)
        #expect(live.costOfLiving.rating == 3)
        #expect(live.healthcare.rating == 9)
    }

    @Test func decodesSingleHeadlinePerCategory() throws {
        let result = try decode()
        #expect(!result.safetyCategories.pettyTheft.headline.isEmpty)
        #expect(!result.liveabilityCategories.walkability.headline.isEmpty)
    }

    @Test func decodesTopRisksAndHighlights() throws {
        let result = try decode()
        #expect(result.safetyTopRisks.count >= 2)
        #expect(result.liveabilityHighlights.count >= 2)
        #expect(result.safetyTopRisks.allSatisfy { !$0.isEmpty })
        #expect(result.liveabilityHighlights.allSatisfy { !$0.isEmpty })
    }

    @Test func decodesNaturalDisasterConcerns() throws {
        let result = try decode()
        #expect(result.naturalDisasterConcerns.count == 2)
        #expect(result.naturalDisasterConcerns.contains("earthquake zone"))
    }

    @Test func decodesLGBTQWarning() throws {
        let result = try decode()
        #expect(result.warnings.lgbtqTravel.rating == 9)
        #expect(!result.warnings.lgbtqTravel.headline.isEmpty)
    }

    @Test func safetyScoreIsMeanOfNineSafetyCategories() throws {
        let result = try decode()
        let ratings = [3, 7, 8, 6, 9, 4, 5, 7, 8]
        let expected = Double(ratings.reduce(0, +)) / Double(ratings.count)
        #expect(abs(result.safetyScore - expected) < 0.001)
    }

    @Test func liveabilityScoreIsMeanOfSixCategories() throws {
        let result = try decode()
        let ratings = [8, 9, 6, 5, 3, 9]
        let expected = Double(ratings.reduce(0, +)) / Double(ratings.count)
        #expect(abs(result.liveabilityScore - expected) < 0.001)
    }
}
