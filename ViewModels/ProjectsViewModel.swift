//
//  ProjectsViewModel.swift
//  WandbApp
//
//  View model for managing projects
//

import Foundation
import Combine

class ProjectsViewModel: ObservableObject {
    @Published var projects: [WandbProject] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    var apiKey: String = ""
    var entity: String = ""
    
    private let apiService = WandbAPIService()
    
    func setCredentials(apiKey: String, entity: String) {
        self.apiKey = apiKey
        self.entity = entity
        apiService.setCredentials(apiKey: apiKey, entity: entity)
    }
    
    @MainActor
    func fetchProjects() async {
        isLoading = true
        errorMessage = ""
        
        // Debug: verify credentials are set
        if apiKey.isEmpty {
            print("ERROR: API key is empty in ViewModel!")
            errorMessage = "API key not set. Please log in again."
            isLoading = false
            return
        }
        print("Fetching projects - API key length: \(apiKey.count), entity: \(entity)")
        
        do {
            let fetchedProjects = try await apiService.fetchProjects(
                entity: entity,
                apiKey: apiKey
            )
            projects = fetchedProjects
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching projects: \(error)")
        }
        
        isLoading = false
    }
}
