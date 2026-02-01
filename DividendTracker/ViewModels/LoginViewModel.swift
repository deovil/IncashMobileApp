//
//  LoginViewModel.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 21/01/26.
//

import Foundation

@MainActor
class LoginViewModel: ObservableObject {
    @Published var accessToken: String?
    @Published var errorMessage: String?
    @Published var isCheckingAuth = true
    @Published var isLoggedOut = false
    
    init() {
        listenNotification()
    }
    
    private func listenNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(logout),
            name: .userLogout,
            object: nil
        )
    }
    
    private func settingAuthInProgressFlags() {
        isCheckingAuth = true
        errorMessage = nil
    }

    func signIn() {
        self.settingAuthInProgressFlags()
        
        AuthService.shared.signIn { [weak self] result in
            switch result {
            case .success(let token):
                self?.isCheckingAuth = false
                self?.accessToken = token

            case .failure(let error):
                self?.isCheckingAuth = false
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func restoreSessionIfPossible() {
        self.settingAuthInProgressFlags()
        
        Task {
            do {
                let token = try await AuthService.shared.getAccessToken()
                self.isCheckingAuth = false
                if !token.isEmpty {
                    self.accessToken = token
                }
            } catch {
                self.isCheckingAuth = false
            }
        }
    }
    
    @objc
    func logout() {
        AuthService.shared.signOut()
        accessToken = nil
        errorMessage = nil
        isCheckingAuth = false
        isLoggedOut = true
    }
}
