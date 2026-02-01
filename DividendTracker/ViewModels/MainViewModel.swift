//
//  MainViewModel.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 22/01/26.
//

import SwiftUI
import Foundation
import NaturalLanguage

@MainActor
final class MainViewModel: ObservableObject {

    @Published var remoteDividendData: [DividendBatchResult] = []
    @Published var manualDividendData: [DividendBatchResult] = []
    @Published var isLoading = false
    
    private let dividendQuery = "after:2026/01/01 subject:dividend"

    private let service = GmailAPIService()
    private let gemini = GeminiService()
    var accessToken: String
    
    public init(token: String) {
        self.accessToken = token
        self.manualDividendData = populateDataFromDB("manual")
        self.remoteDividendData = populateDataFromDB("remote")
    }
    
    private func populateDataFromDB(_ type: String) -> [DividendBatchResult] {
        let manualDataFromDB = DividendDBHelper.shared.getDataFromSourceType(type)
        var array = [DividendBatchResult]()
        
        for each in manualDataFromDB {
            let newResult: DividendBatchResult = .init(
                ticker: each.ticker,
                companyName: each.companyName,
                netDividend: each.netDividend,
                dataSourceType: type
            )
            array.append(newResult)
        }
        return array
    }
    
    private func extractHeader(_ name: String, from headers: [GmailHeader]) -> String {
        headers.first { $0.name == name }?.value ?? ""
    }
    
    private func extractBody(from payload: GmailPayload) -> String {
        if let data = payload.body?.data,
           let decoded = data.decodeBase64URLSafe() {
            return decoded
        }

        if let parts = payload.parts {
            for part in parts {
                let body = extractBody(from: part)
                if !body.isEmpty {
                    return body
                }
            }
        }

        return ""
    }
    
    private func extractNettDividendInfo(from text: String) -> String? {
        let pattern = #"Net Dividend.*?(\d+(?:\.\d+)?)"#

        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        if let match = regex.firstMatch(in: text, options: [], range: range),
           let amountRange = Range(match.range(at: 1), in: text) {
            return String(text[amountRange])
        }

        return nil
    }
    
    private func extractCompanyName(from text: String) -> String? {
        let pattern = #"([A-Z][A-Z\s&.-]+(?:LIMITED|LTD\.?|PRIVATE LIMITED|PVT\.?\s?LTD\.?|PLC|INC|CORPORATION|CO\.?\s?LTD|COMPANY LIMITED))"#

        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        if let match = regex.firstMatch(in: text, options: [], range: range),
           let companyRange = Range(match.range(at: 1), in: text) {

            return String(text[companyRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }
    
    private func getCleanedEmailBody(_ text: String) -> String {
        let companyName = extractCompanyName(from: text) ?? ""
        let netDividendInfo = extractNettDividendInfo(from: text) ?? ""
        
        return "Company: \(companyName) \n\n Net Dividend: \(netDividendInfo)"
    }

    private func getColor(index: Int, total: Int) -> Color {
        if total == 1 {
            return Color(red: 0.67, green: 0.05, blue: 0.43)
        }
        
        let ratio = Double(index) / Double(total - 1)
        let startColor = (r: 0.67, g: 0.05, b: 0.43)
        let endColor = (r: 1.0, g: 1.0, b: 1.0)
        
        let r = startColor.r + (endColor.r - startColor.r) * ratio
        let g = startColor.g + (endColor.g - startColor.g) * ratio
        let b = startColor.b + (endColor.b - startColor.b) * ratio
        
        return Color(red: r, green: g, blue: b)
    }
    
    func getTotalDividendData() -> [DividendItem] {
        var combinedData: [String: (name: String, amount: Double)] = [:]
        
        // Add remote dividend data
        for result in remoteDividendData {
            combinedData[result.ticker] = (name: result.companyName, amount: result.netDividend)
        }
        
        // Add manual dividend data, combining amounts for duplicate tickers
        for result in manualDividendData {
            if let existing = combinedData[result.ticker] {
                combinedData[result.ticker] = (name: result.companyName, amount: existing.amount + result.netDividend)
            } else {
                combinedData[result.ticker] = (name: result.companyName, amount: result.netDividend)
            }
        }
        
        // Convert to array and sort
        let items = combinedData.map { (ticker: $0.key, name: $0.value.name, amount: $0.value.amount) }
        let sorted = items.sorted { $0.amount > $1.amount }
        let total = sorted.reduce(0) { $0 + $1.amount }
        
        return sorted.enumerated().map { index, item in
            let percent = total > 0 ? (item.amount / total) * 100 : 0
            return DividendItem(
                ticker: item.ticker,
                name: item.name,
                amount: item.amount,
                color: getColor(index: index, total: sorted.count),
                percentage: String(format: "%.1f%%", percent)
            )
        }
    }

    func getRemoteDividendData() -> [DividendItem] {
        let items = self.remoteDividendData.compactMap { result -> (ticker: String, name: String, amount: Double)? in
            return (ticker: result.ticker, name: result.companyName, amount: result.netDividend)
        }
        
        let sorted = items.sorted { $0.amount > $1.amount }
        let total = sorted.reduce(0) { $0 + $1.amount }
        
        return sorted.enumerated().map { index, item in
            let percent = total > 0 ? (item.amount / total) * 100 : 0
            return DividendItem(
                ticker: item.ticker,
                name: item.name,
                amount: item.amount,
                color: getColor(index: index, total: sorted.count),
                percentage: String(format: "%.1f%%", percent)
            )
        }
    }
    
    func getManualDividendData() -> [DividendItem] {
        let items = self.manualDividendData.compactMap { result -> (ticker: String, name: String, amount: Double)? in
            return (ticker: result.ticker, name: result.companyName, amount: result.netDividend)
        }
        
        let sorted = items.sorted { $0.amount > $1.amount }
        let total = sorted.reduce(0) { $0 + $1.amount }
        
        return sorted.enumerated().map { index, item in
            let percent = total > 0 ? (item.amount / total) * 100 : 0
            return DividendItem(
                ticker: item.ticker,
                name: item.name,
                amount: item.amount,
                color: getColor(index: index, total: sorted.count),
                percentage: String(format: "%.1f%%", percent)
            )
        }
    }

    func loadEmails() async {
        isLoading = true
        remoteDividendData = []
        var array = [String]()
        do {
            let messages = try await service.fetchMessageIDs(accessToken: accessToken, query: dividendQuery)
            print("Getting message ID's api success")
            for message in messages.prefix(10) {
                let detail = try await service.fetchMessageDetail(
                    id: message.id,
                    accessToken: accessToken
                )
                print("Getting detail for ID api success")
                let body = extractBody(from: detail.payload)
                
                array.append(body)
            }
            var cleanedUpMails = [String]()
            for email in array {
                let cleanedUpEmail = self.getCleanedEmailBody(email)
                cleanedUpMails.append(cleanedUpEmail)
            }
            let geminiResponse = try await gemini.extractDividendsBatch(emails: cleanedUpMails)
            for response in geminiResponse {
                if let tiker = response.ticker {
                    
                    let companyName = response.companyName ?? "Unknown"
                    let netDividend = response.netDividend ?? 0
                    
                    if let index = remoteDividendData.firstIndex(where: { $0.ticker == tiker }) {
                        let currentDividend = remoteDividendData[index].netDividend
                        remoteDividendData[index].netDividend = currentDividend + (response.netDividend ?? 0)
                    } else {
                        remoteDividendData.append(DividendBatchResult(ticker: tiker, companyName: companyName, netDividend: netDividend, dataSourceType: "remote"))
                    }
                }
            }
            // save each entry in DB and update duplicate entry if present
            for each in remoteDividendData {
                print("---TICKER = \(each.ticker), ---COMPANY = \(String(describing: each.companyName)), ---DIVIDEND = \(each.netDividend)")
                DividendDBHelper.shared.saveAll(remoteDividendData)
            }
        } catch {
            print("Gmail error:", error)
        }
        isLoading = false
    }
    
    func addManualDividend(ticker: String, companyName: String, amount: Double) {
        let newEntry = DividendBatchResult(ticker: ticker, companyName: companyName, netDividend: amount, dataSourceType: "manual")
        manualDividendData.append(newEntry)
        DividendDBHelper.shared.createEntry(ticker: ticker, companyName: companyName, netDividend: amount, dataSourceType: "manual")
    }
    
    func updateManualDividend(ticker: String, companyName: String, amount: Double) {
        if let index = manualDividendData.firstIndex(where: { $0.ticker == ticker }) {
            manualDividendData[index].companyName = companyName
            manualDividendData[index].netDividend = amount
        }
        DividendDBHelper.shared.deleteByTickerAndSource(ticker, "manual")
        DividendDBHelper.shared.createEntry(ticker: ticker, companyName: companyName, netDividend: amount, dataSourceType: "manual")
    }
    
    func deleteManualDividend(ticker: String) {
        manualDividendData.removeAll { $0.ticker == ticker }
        DividendDBHelper.shared.deleteByTickerAndSource(ticker, "manual")
    }
    
    func triggerLogout() {
        NotificationCenter.default.post(name: .userLogout, object: nil)
    }
}
