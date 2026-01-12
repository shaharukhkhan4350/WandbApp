//
//  MainTabView.swift
//  WandbApp
//
//  Main tab view with projects and runs
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = ProjectsViewModel()
    
    var body: some View {
        TabView {
            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }
            
            RunsView()
                .tabItem {
                    Label("Runs", systemImage: "chart.bar")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(viewModel)
        .onAppear {
            viewModel.setCredentials(
                apiKey: authManager.apiKey,
                entity: authManager.entity
            )
        }
    }
}
