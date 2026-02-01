//
//  LoginView.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 24/01/26.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        if let token = viewModel.accessToken {
            MainView(viewModel: MainViewModel(token: token))
        } else {
            loginContent
        }
    }
    
    var loginContent: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Circle()
                .fill(AppColors.PINK_COLOR.opacity(0.3))
                .blur(radius: 120)
                .frame(width: 384, height: 384)
                .offset(x: 150, y: -300)
            
            Circle()
                .fill(AppColors.PINK_COLOR.opacity(0.3))
                .blur(radius: 100)
                .frame(width: 320, height: 320)
                .offset(x: -150, y: 300)
            
            VStack(spacing: 48) {
                VStack(spacing: 12) {
                    Text("Welcome to Incash!")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("Dividend tracking made simple")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 16) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            viewModel.isCheckingAuth = true
                        }
                        viewModel.signIn()
                    } label: {
                        HStack(spacing: 12) {
                            if viewModel.isCheckingAuth {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.PINK_COLOR))
                                Text("Signing you In")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppColors.PINK_COLOR)
                            } else {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 24))
                                Text("Sign in with Google")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .foregroundColor(viewModel.isCheckingAuth ? AppColors.PINK_COLOR : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(viewModel.isCheckingAuth ? Color.black : AppColors.PINK_COLOR)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.PINK_COLOR, lineWidth: 2)
                        )
                        .shadow(color: AppColors.PINK_COLOR.opacity(0.2), radius: 15, y: 4)
                    }
                    .disabled(viewModel.isCheckingAuth)
                    .animation(.easeInOut(duration: 0.05), value: viewModel.isCheckingAuth)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("Disclaimer: App will access your Gmail account to fetch Dividend data.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: 480)
        }
        .task {
            viewModel.restoreSessionIfPossible()
        }
    }
}

#Preview {
    LoginView()
}



