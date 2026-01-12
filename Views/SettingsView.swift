//
//  SettingsView.swift
//  WandbApp
//
//  Settings view with logout option
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    HStack {
                        Text("Entity")
                        Spacer()
                        Text(authManager.entity)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        authManager.logout()
                    }) {
                        HStack {
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
