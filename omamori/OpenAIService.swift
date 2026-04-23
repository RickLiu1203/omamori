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
        longitude: Double
    ) async throws -> String {
        let apiKey = Secrets.openAIAPIKey
        guard !apiKey.isEmpty, apiKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw NSError(
                domain: "OpenAI",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not set. Add your key in Secrets.swift."]
            )
        }

        let locationDescription = [neighborhood, city, country]
            .compactMap { $0 }
            .joined(separator: ", ")

        let prompt = """
        You are a travel safety advisor. Provide a brief safety assessment for a traveler \
        currently at: \(locationDescription) (coordinates: \(latitude), \(longitude)).

        Include: overall safety rating, key safety tips, areas to avoid, emergency numbers, \
        and any current advisories. Keep it concise and practical.
        """

        let requestBody = ChatRequest(
            model: "gpt-4o-mini",
            messages: [.init(role: "user", content: prompt)],
            max_tokens: 500
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
