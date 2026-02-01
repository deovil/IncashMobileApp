//
//  Extension.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 22/01/26.
//

import Foundation

extension String {
    func decodeBase64URLSafe() -> String? {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let paddingLength = 4 - base64.count % 4
        if paddingLength < 4 {
            base64 += String(repeating: "=", count: paddingLength)
        }

        guard let data = Data(base64Encoded: base64) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension Notification.Name {
    static let userLogout = Notification.Name("userLogout")
}
