//
//  OpenAIService.swift
//  omamori
//
//  Created by RickLiu1203 on 2026-04-23.
//

import Foundation

enum OpenAIService {

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [Message]
        let max_tokens: Int
        let response_format: ResponseFormat

        struct Message: Encodable {
            let role: String
            let content: String
        }

        struct ResponseFormat: Encodable {
            let type: String
            let json_schema: JSONSchemaWrapper
        }

        struct JSONSchemaWrapper: Encodable {
            let name: String
            let strict: Bool
            let schema: JSONSchema
        }

        struct JSONSchema: Encodable {
            let type: String
            let properties: [String: SchemaProperty]
            let required: [String]
            let additionalProperties: Bool
        }

        final class SchemaProperty: Encodable {
            let type: String?
            let description: String?
            let properties: [String: SchemaProperty]?
            let required: [String]?
            let additionalProperties: Bool?
            let minimum: Int?
            let maximum: Int?
            let items: SchemaProperty?

            init(
                type: String? = nil,
                description: String? = nil,
                properties: [String: SchemaProperty]? = nil,
                required: [String]? = nil,
                additionalProperties: Bool? = nil,
                minimum: Int? = nil,
                maximum: Int? = nil,
                items: SchemaProperty? = nil
            ) {
                self.type = type
                self.description = description
                self.properties = properties
                self.required = required
                self.additionalProperties = additionalProperties
                self.minimum = minimum
                self.maximum = maximum
                self.items = items
            }
        }
    }

    private struct ChatResponse: Decodable {
        let choices: [Choice]

        struct Choice: Decodable {
            let message: MessageContent
        }

        struct MessageContent: Decodable {
            let content: String
        }
    }

    private struct ResponsesRequest: Encodable {
        let model: String
        let tools: [Tool]
        let input: String

        struct Tool: Encodable {
            let type: String
        }
    }

    private struct ResponsesResponse: Decodable {
        let output: [OutputItem]

        struct OutputItem: Decodable {
            let type: String
            let content: [ContentBlock]?
        }

        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
    }

    private static let safetyCalibrationAnchors = """
    SAFETY CALIBRATION ANCHORS:
    Format: neighborhood | petty_theft | robbery | assault | sexual_har | hate_crime | scams_fraud | night | transport | street | solo | female | lgbtq

    Singapore Marina Bay:        9|10|10|8|9|8|9|10|10|10|9|10
    Reykjavik 101:               8|10|9|9|9|9|9|10|10|10|9|10
    Tokyo Marunouchi:            9|10|10|5|8|9|9|9|9|9|6|8
    Zurich Bahnhofstrasse:       9|10|10|9|9|9|9|10|10|10|9|10
    Barcelona Gothic Quarter:    2|5|7|7|8|5|7|8|5|7|6|8
    Prague Old Town:             4|8|8|8|7|2|7|8|7|8|7|8
    Seoul Itaewon:               7|8|6|5|3|7|5|8|6|7|5|6
    Buenos Aires San Telmo:      3|4|6|6|8|5|5|6|6|6|5|7
    Marrakech Medina:            5|8|8|3|7|2|6|5|6|4|2|3
    Paris Gare du Nord:          3|5|5|5|7|5|4|6|3|5|4|7
    Shinjuku Kabukicho:          6|8|7|3|7|2|4|6|5|5|3|5
    Hamilton ON Downtown:        6|6|5|7|7|8|5|6|2|5|6|8
    Bangkok Khao San Road:       4|7|7|5|7|2|5|5|4|6|4|6
    Cairo Khan el-Khalili:       5|7|7|2|6|3|5|4|5|4|2|2
    LA Skid Row:                 4|3|3|4|6|6|2|5|1|2|3|5
    Johannesburg Hillbrow:       3|2|2|3|5|5|2|4|4|2|2|3
    Naples Quartieri Spagnoli:   2|3|5|6|7|5|4|3|5|4|5|6
    Tijuana Zona Norte:          5|3|3|3|6|4|2|3|4|2|2|4
    Caracas Petare:              2|1|1|2|5|4|1|1|3|1|1|2
    Maiduguri Old Town Nigeria:  5|3|2|4|4|6|2|2|5|1|1|2
    """

    private static let liveabilityCalibrationAnchors = """
    LIVEABILITY CALIBRATION ANCHORS (10 = best for residents):
    Format: neighborhood | walkability | transit | climate | pollution | cost_of_living | healthcare
    Note: cost_of_living — 10 = very affordable, 1 = extremely expensive

    Singapore Marina Bay:    8|10|6|7|2|10
    Tokyo Shinjuku:          9|10|6|8|4|9
    Zurich City Centre:      9|10|7|9|1|10
    Paris 11th Arr.:         9|9|7|7|4|9
    Vienna Innere Stadt:     9|10|7|8|3|10
    Copenhagen Nørrebro:     9|9|7|9|3|10
    Melbourne CBD:           7|8|7|8|4|8
    Barcelona Eixample:      9|8|8|7|5|8
    Bangkok Sukhumvit:       6|7|4|4|7|7
    Medellín El Poblado:     6|5|8|6|8|6
    Cairo Zamalek:           6|4|5|3|6|5
    Lagos Victoria Island:   4|3|5|3|5|5
    Mumbai Dharavi:          6|6|5|3|9|4
    Nairobi CBD:             5|4|7|4|6|5
    LA Koreatown:            6|5|8|5|4|6
    """

    private static var responseFormat: ChatRequest.ResponseFormat {
        let categorySchema = ChatRequest.SchemaProperty(
            type: "object",
            properties: [
                "rating": ChatRequest.SchemaProperty(
                    type: "integer",
                    description: "Rating from 1 to 10 (10 = best/safest)"
                ),
                "headline": ChatRequest.SchemaProperty(
                    type: "string",
                    description: "4–6 word standalone headline for this category"
                )
            ],
            required: ["rating", "headline"],
            additionalProperties: false
        )

        let stringArray = ChatRequest.SchemaProperty(
            type: "array",
            description: "2–3 items, each ≤8 words",
            items: ChatRequest.SchemaProperty(type: "string")
        )

        let disasterArray = ChatRequest.SchemaProperty(
            type: "array",
            description: "0–3 specific natural hazards (e.g. 'earthquake zone', 'flood plains'). Empty if none.",
            items: ChatRequest.SchemaProperty(type: "string")
        )

        return ChatRequest.ResponseFormat(
            type: "json_schema",
            json_schema: ChatRequest.JSONSchemaWrapper(
                name: "area_assessment",
                strict: true,
                schema: ChatRequest.JSONSchema(
                    type: "object",
                    properties: [
                        "neighborhood":             ChatRequest.SchemaProperty(type: "string", description: "Resolved neighborhood name"),
                        "safety_top_risks":         stringArray,
                        "liveability_highlights":   stringArray,
                        "natural_disaster_concerns": disasterArray,
                        "safety_categories": ChatRequest.SchemaProperty(
                            type: "object",
                            properties: [
                                "petty_theft":           categorySchema,
                                "robbery":               categorySchema,
                                "assault":               categorySchema,
                                "sexual_harassment":     categorySchema,
                                "hate_crime":            categorySchema,
                                "scams_and_fraud":       categorySchema,
                                "night_safety":          categorySchema,
                                "street_safety":         categorySchema,
                                "transportation_safety": categorySchema
                            ],
                            required: ["petty_theft", "robbery", "assault", "sexual_harassment",
                                       "hate_crime", "scams_and_fraud", "night_safety",
                                       "street_safety", "transportation_safety"],
                            additionalProperties: false
                        ),
                        "liveability_categories": ChatRequest.SchemaProperty(
                            type: "object",
                            properties: [
                                "walkability":    categorySchema,
                                "transit_access": categorySchema,
                                "climate_index":  categorySchema,
                                "pollution":      categorySchema,
                                "cost_of_living": categorySchema,
                                "healthcare":     categorySchema
                            ],
                            required: ["walkability", "transit_access", "climate_index",
                                       "pollution", "cost_of_living", "healthcare"],
                            additionalProperties: false
                        ),
                        "warnings": ChatRequest.SchemaProperty(
                            type: "object",
                            properties: [
                                "solo_travel":   categorySchema,
                                "female_travel": categorySchema,
                                "lgbtq_travel":  categorySchema
                            ],
                            required: ["solo_travel", "female_travel", "lgbtq_travel"],
                            additionalProperties: false
                        )
                    ],
                    required: ["neighborhood", "safety_top_risks", "liveability_highlights",
                               "natural_disaster_concerns", "safety_categories",
                               "liveability_categories", "warnings"],
                    additionalProperties: false
                )
            )
        )
    }

    static func fetchWebResearch(
        neighborhood: String,
        city: String,
        country: String
    ) async throws -> String {
        let apiKey = Secrets.openAIAPIKey

        let prompt = """
        Search for current safety AND liveability information about \(neighborhood), \(city), \(country).

        Priority 1 — Safety (recent news): crime incidents, safety alerts, \
        protests, police activity in or near \(neighborhood). Include dates.

        Priority 2 — Safety (forums): Reddit, TripAdvisor, Nomad List, expat \
        forums — what do visitors and residents say about crime, nightlife \
        safety, scams, harassment?

        Priority 3 — Liveability: Search for information on walkability and \
        daily errands, public transit quality, cost of living and rent, \
        healthcare access and hospital quality, air quality (AQI data), noise \
        levels (traffic, nightlife, airports), green space availability, \
        climate patterns, and natural disaster history (earthquakes, floods, \
        hurricanes, wildfires, etc.) for \(neighborhood) and \(city).

        Priority 4 — Anchor validation: Check current info for 2-3 comparable \
        reference neighborhoods. Note significant changes.

        Report findings with specifics — dates, incidents, data points, quotes.
        """

        let requestBody = ResponsesRequest(
            model: "gpt-4o-mini",
            tools: [.init(type: "web_search_preview")],
            input: prompt
        )

        var urlRequest = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(requestBody)
        urlRequest.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "OpenAI",
                code: (response as? HTTPURLResponse)?.statusCode ?? 0,
                userInfo: [NSLocalizedDescriptionKey: "Web research failed: \(body)"]
            )
        }

        let responsesResponse = try JSONDecoder().decode(ResponsesResponse.self, from: data)
        let text = responsesResponse.output
            .compactMap { $0.content }
            .flatMap { $0 }
            .compactMap { $0.text }
            .joined(separator: "\n")

        return text.isEmpty ? "No web research results available." : text
    }

    static func fetchSafetyAssessment(
        city: String,
        neighborhood: String?,
        country: String,
        latitude: Double,
        longitude: Double,
        street: String?,
        region: String?,
        areasOfInterest: [String]?,
        placeName: String?,
        webResearch: String
    ) async throws -> SafetyAssessment {
        let apiKey = Secrets.openAIAPIKey
        guard !apiKey.isEmpty, apiKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw NSError(
                domain: "OpenAI",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not set. Add your key in Secrets.swift."]
            )
        }

        let streetDisplay = (street?.isEmpty == false) ? street! : "unknown"
        let areasDisplay = areasOfInterest?.joined(separator: ", ") ?? "none"

        let locationDetails = """
        - Neighborhood/District: \(neighborhood ?? "unknown")
        - Street: \(streetDisplay)
        - Nearby landmark/place: \(placeName ?? "unknown")
        - Areas of interest: \(areasDisplay)
        - City: \(city)
        - Region: \(region ?? "unknown")
        - Country: \(country)
        - Coordinates: \(latitude), \(longitude)
        """

        let resolvedNeighborhood = neighborhood ?? placeName ?? street ?? "\(latitude), \(longitude)"

        let prompt = """
        You are a hyperlocal area rater for both SAFETY and LIVEABILITY. \
        Treat every neighborhood as distinct — Flatiron is NOT the Lower \
        East Side, Trastevere is NOT Testaccio.

        **Device location data:**
        \(locationDetails)

        **Target neighborhood: \(resolvedNeighborhood)**

        **Web research (recent news + forum sentiment + liveability data):**
        \(webResearch)

        \(safetyCalibrationAnchors)

        \(liveabilityCalibrationAnchors)

        ═══════════════════════════════
        SAFETY ASSESSMENT (rate 1–10, 10 = safest):
        ═══════════════════════════════
        Rate these 9 categories for safety_categories:
        petty_theft, robbery, assault, sexual_harassment, hate_crime, \
        scams_and_fraud, night_safety, street_safety, transportation_safety

        Use safety anchors to calibrate. Ground headlines in web research — \
        cite specific streets, incidents, or patterns. Each headline: 4–6 \
        words, standalone phrase.

        safety_top_risks: 2–3 biggest safety concerns, each ≤8 words.

        Warnings (not in safety score):
        solo_travel, female_travel, lgbtq_travel — rate 1–10 and headline.

        ═══════════════════════════════
        LIVEABILITY ASSESSMENT (rate 1–10, 10 = best for residents):
        ═══════════════════════════════
        Rate these 6 categories for liveability_categories:

        - walkability: Access to daily needs on foot — shops, restaurants, \
        errands. 10 = everything walkable.
        - transit_access: Quality, coverage, and reliability of public \
        transport. 10 = excellent network.
        - climate_index: Overall climate livability — temperature, humidity, \
        seasonality, weather stability. 10 = mild, pleasant, stable year-round. \
        Separately list specific natural disaster concerns (earthquakes, \
        floods, hurricanes, wildfires, etc.) in natural_disaster_concerns.
        - pollution: Composite of air quality (AQI/pollution data), noise \
        levels (traffic, nightlife, airports), and green space availability \
        (parks, trees, nature access). 10 = clean air, quiet, abundant green.
        - cost_of_living: Affordability for a resident — rent, groceries, \
        dining, transport costs. 10 = very affordable, 1 = extremely expensive.
        - healthcare: Access to quality hospitals, clinics, specialists, \
        emergency care. 10 = excellent access and quality.

        Use liveability anchors to calibrate. Each headline: 4–6 words.

        liveability_highlights: 2–3 key factors defining liveability here \
        (notable strengths OR concerns), each ≤8 words.

        natural_disaster_concerns: 0–3 specific hazards (e.g. "earthquake \
        zone", "seasonal flooding", "hurricane corridor"). Empty array if \
        no significant risks.
        """

        let requestBody = ChatRequest(
            model: "gpt-4o-mini",
            messages: [.init(role: "user", content: prompt)],
            max_tokens: 2200,
            response_format: responseFormat
        )

        var urlRequest = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "OpenAI",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "API error (\(httpResponse.statusCode)): \(body)"]
            )
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content,
              let jsonData = content.data(using: .utf8) else {
            throw NSError(
                domain: "OpenAI",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No response content from API"]
            )
        }

        return try JSONDecoder().decode(SafetyAssessment.self, from: jsonData)
    }
}
