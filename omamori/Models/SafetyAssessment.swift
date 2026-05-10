//
//  SafetyAssessment.swift
//  omamori
//
//  Created by RickLiu1203 on 2026-04-23.
//

import Foundation

struct SafetyAssessment: Decodable, Identifiable {
    let neighborhood: String
    let touristTopRisks: [String]
    let residentTopRisks: [String]
    let subcategories: Subcategories
    let warnings: Warnings

    var id: String { neighborhood }

    static let warningThreshold = 5

    var overallRating: Double {
        let ratings = [
            subcategories.pettyTheft.rating,
            subcategories.robbery.rating,
            subcategories.assault.rating,
            subcategories.sexualHarassment.rating,
            subcategories.hateCrime.rating,
            subcategories.scamsAndFraud.rating,
            subcategories.nightSafety.rating,
            subcategories.streetSafety.rating,
            subcategories.transportationSafety.rating
        ]
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }

    struct Category: Decodable {
        let rating: Int
        let touristHeadline: String
        let residentHeadline: String

        enum CodingKeys: String, CodingKey {
            case rating
            case touristHeadline = "tourist_headline"
            case residentHeadline = "resident_headline"
        }
    }

    struct Subcategories: Decodable {
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
        case touristTopRisks = "tourist_top_risks"
        case residentTopRisks = "resident_top_risks"
        case subcategories
        case warnings
    }
}
