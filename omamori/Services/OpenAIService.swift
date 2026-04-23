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
        You are a travel safety advisor. A traveler has shared their current location.

        **Resolved location data (from device GPS + reverse geocoding):**
        \(locationDetails)

        **Primary neighborhood: \(resolvedNeighborhood)**
        The neighborhood value above is the authoritative neighborhood identity. \
        Use it as the basis for your entire assessment. Only fall back to \
        coordinates-based neighborhood lookup if it is "unknown".

        **Step 1 — Confirm or refine the neighborhood:**
        Start your response by stating the neighborhood you are assessing. If \
        "\(resolvedNeighborhood)" maps to a commonly known local name that \
        travelers would recognize, mention both. \
        Use areas of interest and the street name for additional context.

        **Step 2 — Safety assessment for that area:**

        1. **Overall Safety Rating**: X/5 with a one-line summary calibrated \
        to this neighborhood, not the city average.
        2. **Neighborhood-Specific Risks**: Pickpocketing hotspots, scam types \
        common here, traffic/road hazards, environmental risks, or civil \
        unrest nearby.
        3. **Time-of-Day Guidance**: How safety shifts between daytime, evening, \
        and late night in this specific area.
        4. **Nearby Areas to Avoid**: Name specific streets, blocks, or adjacent \
        neighborhoods that are higher-risk, with brief reasoning.
        5. **Safe Practices for This Area**: 2-3 concrete, locally relevant tips \
        (not generic "be aware of your surroundings" advice).
        6. **Emergency Contacts**: Local police, ambulance, tourist police (if \
        applicable), nearest embassy/consulate for common nationalities.
        7. **Current Advisories**: Active government travel advisories, recent \
        incidents, protests, or seasonal risks affecting this area right now.

        Keep the tone direct and practical — a worried traveler glancing at \
        their phone, not reading an essay. Prioritize actionable information \
        over disclaimers.
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
