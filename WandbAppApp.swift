//
//  WandbAppApp.swift
//  WandbApp
//
//  Created for wandb iOS app
//

import SwiftUI

@main
struct WandbAppApp: App {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
