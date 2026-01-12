//
//  RunsViewModel.swift
//  WandbApp
//
//  View model for managing runs
//

import Foundation
import Combine

class RunsViewModel: ObservableObject {
    @Published var runs: [WandbRun] = []
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
    func fetchRuns(entity: String, project: String, apiKey: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let fetchedRuns = try await apiService.fetchRuns(
                entity: entity,
                project: project,
                apiKey: apiKey
            )
            runs = fetchedRuns
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching runs: \(error)")
        }
        
        isLoading = false
    }
}
