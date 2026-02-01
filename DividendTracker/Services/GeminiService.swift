//
//  GeminiService.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 23/01/26.
//

import Foundation

final class GeminiService {
    
    private let endpoint =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    private func formatBodiesForPrompt(_ bodies: [String]) -> String {
        bodies.enumerated().map { index, body in
            """
            Email \(index + 1):
            \(body)
            ---
            """
        }.joined(separator: "\n")
    }

    func extractDividendsBatch(
        emails: [String]
    ) async throws -> [DividendBatchResultResponse] {

        let emailsText = formatBodiesForPrompt(emails)

        let prompt = """
        You are given multiple inputs.

        For EACH input:
        - Identify the stock market ticker symbol of the company for ticker field
        - Identify actual name of the company for companyName field
        - Extract the nett dividend amount (number only) for netDividend field

        Rules:
        - Return ONLY valid JSON return it as JSON string instead of markdown
        - Do NOT add explanations
        - If data is missing, use null
        - Maintain the same order as input

        Output JSON format:
        [
          {
            "ticker": string | null,
            "companyName": string | null,
            "netDividend": number | null
          }
        ]

        Emails:
        \(emailsText)
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]

        var request = URLRequest(
            url: URL(string: "\(endpoint)?key=\(AppSecrets.geminiAPIKey)")!
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Gemini API Status Code: \(httpResponse.statusCode)")
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Gemini API Response: \(responseString)")
        }

        let geminiResponse = try JSONDecoder().decode(GeminiAPIResponse.self, from: data)

        guard
            let jsonText = geminiResponse
                .candidates
                .first?
                .content
                .parts
                .first?
                .text
        else {
            throw NSError(domain: "GeminiBatch", code: -1, userInfo: [NSLocalizedDescriptionKey: "No valid response from Gemini API"])
        }
        
        let cleanJSON = jsonText
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanJSON.data(using: .utf8) else {
            throw NSError(domain: "JSON Parsing", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON string to data"])
        }
        
        return try JSONDecoder().decode(
            [DividendBatchResultResponse].self,
            from: jsonData
        )
    }
}
