//
//  SafetyAssessment.swift
//  omamori
//
//  Created by RickLiu1203 on 2026-04-23.
//

import Foundation

struct SafetyAssessment: Decodable, Identifiable {
    let neighborhood: String
    let safetyTopRisks: [String]
    let liveabilityHighlights: [String]
    let naturalDisasterConcerns: [String]
    let safetyCategories: SafetyCategories
    let liveabilityCategories: LiveabilityCategories
    let warnings: Warnings

    var id: String { neighborhood }

    static let warningThreshold = 5

    var safetyScore: Double {
        let ratings = [
            safetyCategories.pettyTheft.rating,
            safetyCategories.robbery.rating,
            safetyCategories.assault.rating,
            safetyCategories.sexualHarassment.rating,
            safetyCategories.hateCrime.rating,
            safetyCategories.scamsAndFraud.rating,
            safetyCategories.nightSafety.rating,
            safetyCategories.streetSafety.rating,
            safetyCategories.transportationSafety.rating
        ]
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }

    var liveabilityScore: Double {
        let ratings = [
            liveabilityCategories.walkability.rating,
            liveabilityCategories.transitAccess.rating,
            liveabilityCategories.climateIndex.rating,
            liveabilityCategories.pollution.rating,
            liveabilityCategories.costOfLiving.rating,
            liveabilityCategories.healthcare.rating
        ]
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }

    struct Category: Decodable {
        let rating: Int
        let headline: String
    }

    struct SafetyCategories: Decodable {
        let pettyTheft: Category
        let robbery: Category
        let assault: Category
        let sexualHarassment: Category
        let hateCrime: Category
        let scamsAndFraud: Category
        let nightSafety: Category
        let streetSafety: Category
        let transportationSafety: Category

        enum CodingKeys: String, CodingKey {
            case pettyTheft = "petty_theft"
            case robbery
            case assault
            case sexualHarassment = "sexual_harassment"
            case hateCrime = "hate_crime"
            case scamsAndFraud = "scams_and_fraud"
            case nightSafety = "night_safety"
            case streetSafety = "street_safety"
            case transportationSafety = "transportation_safety"
        }
    }

    struct LiveabilityCategories: Decodable {
        let walkability: Category
        let transitAccess: Category
        let climateIndex: Category
        let pollution: Category
        let costOfLiving: Category
        let healthcare: Category

        enum CodingKeys: String, CodingKey {
            case walkability
            case transitAccess = "transit_access"
            case climateIndex = "climate_index"
            case pollution
            case costOfLiving = "cost_of_living"
            case healthcare
        }
    }

    struct Warnings: Decodable {
        let soloTravel: Category
        let femaleTravel: Category
        let lgbtqTravel: Category

        enum CodingKeys: String, CodingKey {
            case soloTravel = "solo_travel"
            case femaleTravel = "female_travel"
            case lgbtqTravel = "lgbtq_travel"
        }
    }

    enum CodingKeys: String, CodingKey {
        case neighborhood
        case safetyTopRisks = "safety_top_risks"
        case liveabilityHighlights = "liveability_highlights"
        case naturalDisasterConcerns = "natural_disaster_concerns"
        case safetyCategories = "safety_categories"
        case liveabilityCategories = "liveability_categories"
        case warnings
    }
}
