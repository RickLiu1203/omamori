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

        struct SchemaProperty: Encodable {
            let type: String?
            let description: String?
            let properties: [String: SchemaProperty]?
            let required: [String]?
            let additionalProperties: Bool?
            let minimum: Int?
            let maximum: Int?

            init(
                type: String? = nil,
                description: String? = nil,
                properties: [String: SchemaProperty]? = nil,
                required: [String]? = nil,
                additionalProperties: Bool? = nil,
                minimum: Int? = nil,
                maximum: Int? = nil
            ) {
                self.type = type
                self.description = description
                self.properties = properties
                self.required = required
                self.additionalProperties = additionalProperties
                self.minimum = minimum
                self.maximum = maximum
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

    private static let calibrationAnchors = """
    CALIBRATION ANCHORS (baseline — override with web research if outdated):
    Format: neighborhood | petty_theft | robbery | assault | sexual_har | kidnapping | hate_crime | scams | night | org_crime | homeless_drugs | solo | female

    Singapore Marina Bay:        9|10|10|8|10|9|8|9|10|9|10|9
    Reykjavik 101:               8|10|9|9|10|9|9|9|10|8|10|9
    Tokyo Marunouchi:            9|10|10|5|10|8|9|9|9|9|9|6
    Zurich Bahnhofstrasse:       9|10|10|9|10|9|9|9|10|9|10|9
    Barcelona Gothic Quarter:    2|5|7|7|9|8|5|7|7|6|7|6
    Prague Old Town:             4|8|8|8|10|7|2|7|8|7|8|7
    Seoul Itaewon:               7|8|6|5|9|3|7|5|9|6|7|5
    Buenos Aires San Telmo:      3|4|6|6|7|8|5|5|7|6|6|5
    Marrakech Medina:            5|8|8|3|8|7|2|6|7|6|4|2
    Paris Gare du Nord:          3|5|5|5|9|7|5|4|7|3|5|4
    Shinjuku Kabukicho:          6|8|7|3|9|7|2|4|7|5|5|3
    Hamilton ON Downtown:        6|6|5|7|9|7|8|5|6|2|5|6
    Bangkok Khao San Road:       4|7|7|5|8|7|2|5|7|4|6|4
    Cairo Khan el-Khalili:       5|7|7|2|7|6|3|5|6|5|4|2
    LA Skid Row:                 4|3|3|4|8|6|6|2|7|1|2|3
    Johannesburg Hillbrow:       3|2|2|3|4|5|5|2|4|4|2|2
    Naples Quartieri Spagnoli:   2|3|5|6|7|7|5|4|2|5|4|5
    Tijuana Zona Norte:          5|3|3|3|3|6|4|2|1|4|2|2
    Caracas Petare:              2|1|1|2|1|5|4|1|2|3|1|1
    Maiduguri Old Town Nigeria:  5|3|2|4|1|4|6|2|1|5|1|1
    """

    private static var responseFormat: ChatRequest.ResponseFormat {
        let categorySchema = ChatRequest.SchemaProperty(
            type: "object",
            properties: [
                "rating": ChatRequest.SchemaProperty(type: "integer", description: "Rating from 1 to 10 (10 = safest)"),
                "summary": ChatRequest.SchemaProperty(type: "string", description: "1-2 sentence neighborhood-specific explanation")
            ],
            required: ["rating", "summary"],
            additionalProperties: false
        )

        return ChatRequest.ResponseFormat(
            type: "json_schema",
            json_schema: ChatRequest.JSONSchemaWrapper(
                name: "safety_assessment",
                strict: true,
                schema: ChatRequest.JSONSchema(
                    type: "object",
                    properties: [
                        "neighborhood": ChatRequest.SchemaProperty(type: "string", description: "Resolved neighborhood name"),
                        "subcategories": ChatRequest.SchemaProperty(
                            type: "object",
                            properties: [
                                "petty_theft": categorySchema,
                                "robbery": categorySchema,
                                "assault": categorySchema,
                                "sexual_harassment": categorySchema,
                                "kidnapping": categorySchema,
                                "hate_crime": categorySchema,
                                "scams": categorySchema,
                                "night_safety": categorySchema,
                                "organized_crime": categorySchema,
                                "homelessness_and_drugs": categorySchema
                            ],
                            required: ["petty_theft", "robbery", "assault", "sexual_harassment", "kidnapping", "hate_crime", "scams", "night_safety", "organized_crime", "homelessness_and_drugs"],
                            additionalProperties: false
                        ),
                        "warnings": ChatRequest.SchemaProperty(
                            type: "object",
                            properties: [
                                "solo_travel": categorySchema,
                                "female_travel": categorySchema
                            ],
                            required: ["solo_travel", "female_travel"],
                            additionalProperties: false
                        )
                    ],
                    required: ["neighborhood", "subcategories", "warnings"],
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
        Search for current safety information about \(neighborhood), \(city), \(country).

        Priority 1 — Recent news (past month): Search for recent crime \
        incidents, safety alerts, protests, police activity, or notable \
        events in or near \(neighborhood). Include dates and specifics.

        Priority 2 — Forum posts: Search Reddit (r/travel, r/solotravel, \
        city-specific subreddits), TripAdvisor, Nomad List, and expat \
        forums for recent posts about safety in \(neighborhood). What do \
        real visitors and residents say about: crime, nightlife safety, \
        scams, harassment, organized crime, homelessness, drug activity?

        Priority 3 — Anchor validation: Also briefly check current safety \
        info for 3-4 of these reference neighborhoods that are most \
        comparable to \(neighborhood): Barcelona Gothic Quarter, Prague \
        Old Town, Paris Gare du Nord, Shinjuku Kabukicho, Buenos Aires \
        San Telmo, Bangkok Khao San Road, Downtown LA. Note if any have \
        changed significantly (gentrification, increased/decreased crime).

        Summarize findings with specific incidents, locations, dates, and \
        user quotes where possible. Do not editorialize — just report \
        what you find.
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

        let resolvedNeighborhood = neighborhood
            ?? placeName
            ?? street
            ?? "\(latitude), \(longitude)"

        let prompt = """
        You are a hyperlocal travel safety rater. You MUST treat every \
        neighborhood as distinct — Flatiron is NOT the Lower East Side, \
        Shibuya is NOT Shinjuku, Trastevere is NOT Testaccio.

        **Device location data:**
        \(locationDetails)

        **Target neighborhood: \(resolvedNeighborhood)**

        **Web research (recent news + forum sentiment):**
        \(webResearch)

        \(calibrationAnchors)

        INSTRUCTIONS:
        - Use the calibration anchors to position your ratings on a global \
        scale. If the web research contradicts an anchor's baseline rating, \
        trust the web research.
        - Your ratings for \(resolvedNeighborhood) MUST be consistent with \
        the anchor scale. If this area is safer than Barcelona Gothic \
        Quarter for pickpocketing, score higher than 2. If more dangerous \
        than Zurich for assault, score lower than 10.
        - Ground your summaries in the web research — cite specific \
        incidents, forum posts, or patterns found.

        Rate each subcategory 1-10 (10 = safest):
        - petty_theft, robbery, assault, sexual_harassment, kidnapping, \
        hate_crime, scams, night_safety, organized_crime, homelessness_and_drugs

        Warnings (not part of overall score):
        - solo_travel, female_travel

        Each summary must name real streets, landmarks, or patterns. No \
        generic advice.
        """

        let requestBody = ChatRequest(
            model: "gpt-4o-mini",
            messages: [.init(role: "user", content: prompt)],
            max_tokens: 1200,
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
