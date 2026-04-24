//
//  SafetyAssessment.swift
//  omamori
//
//  Created by RickLiu1203 on 2026-04-23.
//

import Foundation

struct SafetyAssessment: Decodable {
    let neighborhood: String
    let subcategories: Subcategories
    let warnings: Warnings

    static let warningThreshold = 5

    var overallRating: Double {
        let ratings = [
            subcategories.pettyTheft.rating,
            subcategories.robbery.rating,
            subcategories.assault.rating,
            subcategories.sexualHarassment.rating,
            subcategories.kidnapping.rating,
            subcategories.hateCrime.rating,
            subcategories.scams.rating,
            subcategories.nightSafety.rating,
            subcategories.organizedCrime.rating,
            subcategories.homelessnessAndDrugs.rating
        ]
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }

    struct Subcategories: Decodable {
        let pettyTheft: Category
        let robbery: Category
        let assault: Category
        let sexualHarassment: Category
        let kidnapping: Category
        let hateCrime: Category
        let scams: Category
        let nightSafety: Category
        let organizedCrime: Category
        let homelessnessAndDrugs: Category

        enum CodingKeys: String, CodingKey {
            case pettyTheft = "petty_theft"
            case robbery
            case assault
            case sexualHarassment = "sexual_harassment"
            case kidnapping
            case hateCrime = "hate_crime"
            case scams
            case nightSafety = "night_safety"
            case organizedCrime = "organized_crime"
            case homelessnessAndDrugs = "homelessness_and_drugs"
        }
    }

    struct Warnings: Decodable {
        let soloTravel: Category
        let femaleTravel: Category

        enum CodingKeys: String, CodingKey {
            case soloTravel = "solo_travel"
            case femaleTravel = "female_travel"
        }
    }

    struct Category: Decodable {
        let rating: Int
        let summary: String
    }
}
