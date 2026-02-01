//
//  DataModels.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 21/01/26.
//

import Foundation

// MARK: GmailAPIService: Models
struct GmailMessageList: Decodable {
    let messages: [GmailMessageSummary]?
    let nextPageToken: String?
    let resultSizeEstimate: Int?
}

struct GmailMessageSummary: Decodable {
    let id: String
    let threadId: String
}

struct GmailMessageDetail: Decodable {
    let id: String
    let payload: GmailPayload
}

struct GmailPayload: Decodable {
    let headers: [GmailHeader]
    let body: GmailBody?
    let parts: [GmailPayload]?
}

struct GmailHeader: Decodable {
    let name: String
    let value: String
}

struct GmailBody: Decodable {
    let data: String?
}

//MARK: Gemini service
struct DividendBatchResultResponse: Decodable {
    let ticker: String?
    let companyName: String?
    var netDividend: Double?
}

struct DividendBatchResult: Decodable {
    let ticker: String
    var companyName: String
    var netDividend: Double
    var dataSourceType: String
}

struct GeminiAPIResponse: Decodable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Decodable {
    let content: GeminiContent
}

struct GeminiContent: Decodable {
    let parts: [GeminiPart]
}

struct GeminiPart: Decodable {
    let text: String
}

