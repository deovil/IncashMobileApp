//
//  AppDelegate.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 21/01/26.
//

import UIKit
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let user = user {
                print("✅ Restored Google Sign-In for:", user.profile?.email ?? "")
            } else {
                print("ℹ️ No previous Google Sign-In")
            }
        }
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        print("Redirecting back to the app from Google Sign-In")
        return GIDSignIn.sharedInstance.handle(url)
    }
}
