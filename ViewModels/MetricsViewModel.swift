//
//  MetricsViewModel.swift
//  WandbApp
//
//  View model for managing training metrics
//

import Foundation
import Combine

class MetricsViewModel: ObservableObject {
    @Published var metrics: [WandbMetric] = []
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
    func fetchMetrics(entity: String, project: String, runId: String, apiKey: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let fetchedMetrics = try await apiService.fetchRunMetrics(
                entity: entity,
                project: project,
                runId: runId,
                apiKey: apiKey
            )
            metrics = fetchedMetrics
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching metrics: \(error)")
        }
        
        isLoading = false
    }
}
