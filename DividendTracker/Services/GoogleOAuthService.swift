//
//  GoogleOAuthService.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 21/01/26.
//

import Foundation
import GoogleSignIn
import UIKit

final class AuthService {

    static let shared = AuthService()
    
    private init() {}

    private let gmailScope = "https://www.googleapis.com/auth/gmail.readonly"

    func signIn(completion: @escaping (Result<String, Error>) -> Void) {

        let config = GIDConfiguration(clientID: AppSecrets.fireBaseClientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let rootVC = UIApplication.shared.rootViewController else {
            return
        }

        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootVC,
            hint: nil,
            additionalScopes: [gmailScope]
        ) { result, error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user found"])))
                return
            }

            user.refreshTokensIfNeeded { user, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let token = user?.accessToken.tokenString ?? ""
                completion(.success(token))
            }
        }
    }
    
    func getAccessToken() async throws -> String {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw NSError(domain: "Can't find user", code: -1)
        }

        let token = try await user.refreshTokensIfNeeded()
        return token.accessToken.tokenString
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}
