//
//  LoginView.swift
//  WandbApp
//
//  Login screen for wandb authentication
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var apiService = WandbAPIService()
    
    @State private var apiKey: String = ""
    @State private var entity: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Logo/Header
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Weights & Biases")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to view your training metrics")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Login Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Entity (Username/Team)")
                            .font(.headline)
                        
                        TextField("Enter your wandb entity", text: $entity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.headline)
                        
                        SecureField("Enter your API key", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    Button(action: handleLogin) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || apiKey.isEmpty || entity.isEmpty)
                    
                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Help text
                VStack(spacing: 4) {
                    Text("Don't have an API key?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link("Get your API key from wandb.ai/settings", 
                         destination: URL(string: "https://wandb.ai/settings")!)
                        .font(.caption)
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func handleLogin() {
        guard !apiKey.isEmpty, !entity.isEmpty else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        showError = false
        
        Task {
            do {
                let isValid = try await apiService.verifyAPIKey(apiKey: apiKey, entity: entity)
                
                await MainActor.run {
                    if isValid {
                        authManager.login(apiKey: apiKey, entity: entity)
                    } else {
                        errorMessage = "Invalid API key or entity"
                        showError = true
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    // Provide more helpful error messages
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .invalidURL:
                            errorMessage = "Invalid API endpoint"
                        case .invalidResponse:
                            errorMessage = "Invalid API key or network error. Please check your API key and try again."
                        case .authenticationFailed:
                            errorMessage = "Authentication failed. Please verify your API key."
                        default:
                            errorMessage = "Failed to authenticate: \(error.localizedDescription)"
                        }
                    } else {
                        errorMessage = "Failed to authenticate: \(error.localizedDescription)\n\nPlease check:\n• Your API key is correct\n• You have internet connection\n• Your entity name matches your wandb username"
                    }
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}
