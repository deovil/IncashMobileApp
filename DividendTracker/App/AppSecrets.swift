//
//  AppSecrets.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 22/01/26.
//

import Foundation

enum AppSecrets {
    static let geminiAPIKey: String = {
        guard let key = Bundle.main
            .infoDictionary?["GEMINI_API_KEY"] as? String else {
            fatalError("Gemini API key missing")
        }
        return key
    }()
    
    static let fireBaseClientID: String = {
        guard let key = Bundle.main
            .infoDictionary?["GID_CLIENT_ID"] as? String else {
            fatalError("FB Client ID key missing")
        }
        return key
    }()
}
