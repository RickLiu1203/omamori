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
      "tourist_top_risks": ["Pickpocket risk high", "Taxi scams common"],
      "resident_top_risks": ["Street theft at night", "Phone snatching"],
      "subcategories": {
        "petty_theft":          {"rating": 3, "tourist_headline": "High pickpocket risk",    "resident_headline": "Wallet theft common"},
        "robbery":              {"rating": 7, "tourist_headline": "Low robbery risk",         "resident_headline": "Generally safe streets"},
        "assault":              {"rating": 8, "tourist_headline": "Rare assault incidents",   "resident_headline": "Safe neighborhood"},
        "sexual_harassment":    {"rating": 6, "tourist_headline": "Some harassment reported", "resident_headline": "Moderate risk areas"},
        "hate_crime":           {"rating": 9, "tourist_headline": "Very few hate crimes",     "resident_headline": "Inclusive community"},
        "scams_and_fraud":      {"rating": 4, "tourist_headline": "Watch for tourist scams",  "resident_headline": "Online fraud common"},
        "night_safety":         {"rating": 5, "tourist_headline": "Risky after midnight",     "resident_headline": "Avoid late nights"},
        "street_safety":        {"rating": 7, "tourist_headline": "Clean busy streets",       "resident_headline": "Manageable environment"},
        "transportation_safety":{"rating": 8, "tourist_headline": "Safe reliable transit",    "resident_headline": "Reliable public transport"}
      },
      "warnings": {
        "solo_travel":   {"rating": 7, "tourist_headline": "Generally safe solo",   "resident_headline": "Solo commute fine"},
        "female_travel": {"rating": 5, "tourist_headline": "Some harassment risk",  "resident_headline": "Vigilance needed"},
        "lgbtq_travel":  {"rating": 9, "tourist_headline": "Welcoming LGBTQ scene","resident_headline": "Open community"}
      }
    }
    """

    private func decode() throws -> SafetyAssessment {
        let data = Self.fixtureJSON.data(using: .utf8)!
        return try JSONDecoder().decode(SafetyAssessment.self, from: data)
    }

    @Test func decodesNineCategories() throws {
        let result = try decode()
        let sub = result.subcategories
        // Access all 9 — if any key is missing decoding would throw
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

    @Test func decodesDualHeadlines() throws {
        let result = try decode()
        let petty = result.subcategories.pettyTheft
        #expect(!petty.touristHeadline.isEmpty)
        #expect(!petty.residentHeadline.isEmpty)
        #expect(petty.touristHeadline != petty.residentHeadline)
    }

    @Test func decodesTopRisksArrays() throws {
        let result = try decode()
        #expect(result.touristTopRisks.count >= 2)
        #expect(result.touristTopRisks.count <= 3)
        #expect(result.residentTopRisks.count >= 2)
        #expect(result.residentTopRisks.count <= 3)
        #expect(result.touristTopRisks.allSatisfy { !$0.isEmpty })
        #expect(result.residentTopRisks.allSatisfy { !$0.isEmpty })
    }

    @Test func decodesLGBTQWarning() throws {
        let result = try decode()
        let lgbtq = result.warnings.lgbtqTravel
        #expect(lgbtq.rating == 9)
        #expect(!lgbtq.touristHeadline.isEmpty)
        #expect(!lgbtq.residentHeadline.isEmpty)
    }

    @Test func overallRatingIsMeanOfNine() throws {
        let result = try decode()
        let ratings = [3, 7, 8, 6, 9, 4, 5, 7, 8]
        let expected = Double(ratings.reduce(0, +)) / Double(ratings.count)
        #expect(abs(result.overallRating - expected) < 0.001)
    }
}
