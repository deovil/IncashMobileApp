//
//  DividendTrackerApp.swift
//  DividendTracker
//
//  Created by Deovil Vimal Dubey on 21/01/26.
//

import SwiftUI

@main
struct DividendTrackerApp: App {
    let persistenceController = PersistenceController.shared
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

