//
//  SplashView.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 24/01/26.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    let splashViewAnimationTime =  1.5
    
    var body: some View {
        if isActive {
            LoginView()
        } else {
            Image("SplashScreen")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + splashViewAnimationTime) {
                        withAnimation {
                            isActive = true
                        }
                    }
                }
        }
    }
}

#Preview {
    SplashView()
}
