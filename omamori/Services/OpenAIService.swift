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

        struct Message: Encodable {
            let role: String
            let content: String
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

    static func fetchSafetyAssessment(
        city: String,
        neighborhood: String?,
        country: String,
        latitude: Double,
        longitude: Double,
        street: String?,
        region: String?,
        areasOfInterest: [String]?,
        placeName: String?
    ) async throws -> String {
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
        You are a hyperlocal travel safety advisor. You MUST treat every \
        neighborhood as distinct — Flatiron is NOT the Lower East Side, \
        Shibuya is NOT Shinjuku, Trastevere is NOT Testaccio. Never give \
        city-wide generic advice.

        **Device location data:**
        \(locationDetails)

        **Target neighborhood: \(resolvedNeighborhood)**

        CRITICAL RULES:
        - Your ENTIRE assessment must be specific to \(resolvedNeighborhood) \
        and the streets immediately around (\(streetDisplay)). If you cannot \
        distinguish this neighborhood from an adjacent one, your answer is wrong.
        - Name real streets, intersections, blocks, and landmarks in this \
        neighborhood. Vague references like "some areas" or "certain streets" \
        are not acceptable.
        - The safety rating must reflect THIS neighborhood specifically. A 4/5 \
        neighborhood and a 2/5 neighborhood in the same city MUST get different \
        ratings.

        Respond with EXACTLY these sections:

        **📍 [Neighborhood name]** (and any local aliases travelers would know)
        One sentence placing this neighborhood: what's it near, what's it known for.

        **Safety: X/5**
        One-line verdict specific to this block-level area.

        **Risks here specifically:**
        - Name the exact scams, crime patterns, or hazards documented in THIS \
        neighborhood. Reference specific streets or corners where they occur. \
        Not "pickpocketing can occur" — WHERE in this neighborhood and HOW.

        **Day vs. night:**
        How does THIS specific area change after dark? Name the streets or \
        blocks where the shift is most noticeable.

        **Avoid nearby:**
        Name 2-3 specific adjacent streets, blocks, or neighborhoods that are \
        higher-risk and WHY. Use real names a local would recognize.

        **Do this here:**
        2-3 concrete tips that ONLY apply to this neighborhood. Not "watch your \
        belongings" — what specific local behavior, route, or practice helps here.

        **Emergency:**
        Local emergency number, nearest police station to this location, tourist \
        police if they exist.

        **Right now:**
        Any current advisories, recent incidents, protests, or seasonal risks \
        affecting this specific area.

        Be blunt. No disclaimers, no "as with any city" filler. A traveler is \
        standing HERE right now and needs to know what's different about THIS \
        spot versus two neighborhoods over.
        """

        let requestBody = ChatRequest(
            model: "gpt-4o-mini",
            messages: [.init(role: "user", content: prompt)],
            max_tokens: 1000
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
        guard let content = chatResponse.choices.first?.message.content else {
            throw NSError(
                domain: "OpenAI",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No response content from API"]
            )
        }

        return content
    }
}
