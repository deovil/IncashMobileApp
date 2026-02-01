//
//  GmailAPIService.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 22/01/26.
//

import Foundation

final class GmailAPIService {
    
    private let baseURL = "https://gmail.googleapis.com/gmail/v1/users/me"

    func fetchMessageIDs(accessToken: String, query: String) async throws -> [GmailMessageSummary] {
        var components = URLComponents(
            string: "\(baseURL)/messages"
        )!
        
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "100")
        ]

        var request = URLRequest(url: components.url!)

        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GmailMessageList.self, from: data)

        return response.messages ?? []
    }

    func fetchMessageDetail(id: String, accessToken: String) async throws -> GmailMessageDetail {
        let url = URL(string: "\(baseURL)/messages/\(id)")!
        var request = URLRequest(url: url)

        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(GmailMessageDetail.self, from: data)
    }
}
