//
//  AuthenticationManager.swift
//  WandbApp
//
//  Manages wandb authentication state
//

import Foundation
import Combine

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var apiKey: String = ""
    @Published var entity: String = ""
    
    private let keychainService = "com.wandb.app"
    private let apiKeyKey = "wandb_api_key"
    private let entityKey = "wandb_entity"
    
    init() {
        loadCredentials()
    }
    
    func login(apiKey: String, entity: String) {
        // Validate API key - wandb API keys are typically 40-60 characters
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedKey.isEmpty || trimmedKey.count < 20 || trimmedKey.count > 200 {
            print("WARNING: API key length seems invalid: \(trimmedKey.count) characters")
        }
        
        // Don't save if it looks like an error message
        if trimmedKey.lowercased().contains("viewer") || 
           trimmedKey.lowercased().contains("error") ||
           trimmedKey.lowercased().contains("null") {
            print("ERROR: API key appears to be an error message, not saving!")
            return
        }
        
        self.apiKey = trimmedKey
        self.entity = entity.trimmingCharacters(in: .whitespacesAndNewlines)
        saveCredentials()
        isAuthenticated = true
    }
    
    func logout() {
        apiKey = ""
        entity = ""
        clearCredentials()
        isAuthenticated = false
    }
    
    private func saveCredentials() {
        KeychainHelper.save(key: apiKeyKey, value: apiKey)
        UserDefaults.standard.set(entity, forKey: entityKey)
    }
    
    private func loadCredentials() {
        if let savedApiKey = KeychainHelper.load(key: apiKeyKey),
           let savedEntity = UserDefaults.standard.string(forKey: entityKey),
           !savedApiKey.isEmpty {
            // Validate loaded API key - if it looks like an error, don't use it
            if savedApiKey.lowercased().contains("viewer") || 
               savedApiKey.lowercased().contains("error") ||
               savedApiKey.lowercased().contains("null") ||
               savedApiKey.count > 200 {
                print("WARNING: Loaded API key appears corrupted, clearing it")
                clearCredentials()
                return
            }
            self.apiKey = savedApiKey
            self.entity = savedEntity
            self.isAuthenticated = true
        }
    }
    
    private func clearCredentials() {
        KeychainHelper.delete(key: apiKeyKey)
        UserDefaults.standard.removeObject(forKey: entityKey)
    }
}
