//
//  WandbAPIService.swift
//  WandbApp
//
//  Service for interacting with wandb API
//

import Foundation
import Combine

class WandbAPIService: ObservableObject {
    private let baseURL = "https://api.wandb.ai"
    private var apiKey: String = ""
    private var entity: String = ""
    
    func setCredentials(apiKey: String, entity: String) {
        self.apiKey = apiKey
        self.entity = entity
    }
    
    // Create Basic Auth header as wandb expects: "api:API_KEY" base64 encoded
    private func createAuthHeader(apiKey: String) -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let credentials = "api:\(trimmedKey)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            print("Failed to create credentials data")
            return ""
        }
        let base64Credentials = credentialsData.base64EncodedString()
        let authHeader = "Basic \(base64Credentials)"
        // Debug: print first/last few chars of key (don't print full key for security)
        if !trimmedKey.isEmpty {
            let keyPreview = String(trimmedKey.prefix(4)) + "..." + String(trimmedKey.suffix(4))
            print("Creating auth header for key: \(keyPreview)")
        }
        return authHeader
    }
    
    // Verify API key using GraphQL viewer query (same as wandview app)
    func verifyAPIKey(apiKey: String, entity: String) async throws -> Bool {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Use GraphQL endpoint like wandview does
        guard let url = URL(string: "\(baseURL)/graphql") else {
            throw APIError.invalidURL
        }
        
        // GraphQL query to verify authentication
        let graphQLQuery = """
        query Viewer {
            viewer {
                id
                username
            }
        }
        """
        
        let requestBody: [String: Any] = [
            "query": graphQLQuery
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw APIError.invalidURL
        }
        
        // Use Basic Authentication as wandb expects: "api:API_KEY" base64 encoded
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(createAuthHeader(apiKey: trimmedKey), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                // Check if response contains viewer data
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   dataDict["viewer"] != nil {
                    return true
                } else {
                    // Check for errors in GraphQL response
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errors = json["errors"] as? [[String: Any]],
                       !errors.isEmpty {
                        if let errorData = String(data: data, encoding: .utf8) {
                            print("GraphQL Error Response: \(errorData)")
                        }
                        throw APIError.authenticationFailed
                    }
                    throw APIError.authenticationFailed
                }
            } else {
                // Log error for debugging
                if let errorData = String(data: data, encoding: .utf8) {
                    print("API Error Response: \(errorData)")
                    print("Status Code: \(httpResponse.statusCode)")
                }
                throw APIError.authenticationFailed
            }
        }
        
        throw APIError.authenticationFailed
    }
    
    // Fetch projects using GraphQL
    func fetchProjects(entity: String, apiKey: String) async throws -> [WandbProject] {
        // Use stored API key if passed key is empty
        let keyToUse = apiKey.isEmpty ? self.apiKey : apiKey
        
        // Debug: verify API key is not empty
        if keyToUse.isEmpty {
            print("ERROR: API key is empty in fetchProjects! Passed: \(apiKey.count), Stored: \(self.apiKey.count)")
            throw APIError.authenticationFailed
        }
        print("Fetching projects - API key length: \(keyToUse.count), entity: \(entity)")
        
        guard let url = URL(string: "\(baseURL)/graphql") else {
            throw APIError.invalidURL
        }
        
        // GraphQL query to fetch projects (exact same as wandview)
        let graphQLQuery = """
        query {
            viewer {
                projects(order: "-createdAt") {
                    pageInfo {
                        hasNextPage
                        hasPreviousPage
                        startCursor
                        endCursor
                    }
                    edges {
                        node {
                            id
                            name
                            createdAt
                            entityName
                        }
                    }
                }
            }
        }
        """
        
        let requestBody: [String: Any] = [
            "query": graphQLQuery
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw APIError.invalidURL
        }
        
        let authHeader = createAuthHeader(apiKey: keyToUse)
        if authHeader.isEmpty {
            print("ERROR: Auth header is empty! keyToUse length: \(keyToUse.count)")
            throw APIError.authenticationFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Debug: verify auth header is set
        if let headerValue = request.value(forHTTPHeaderField: "Authorization") {
            print("fetchProjects - Auth header: \(String(headerValue.prefix(30)))...")
        } else {
            print("ERROR: Authorization header not set!")
            throw APIError.authenticationFailed
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("ERROR: Response is not HTTPURLResponse")
            throw APIError.invalidResponse
        }
        
        print("fetchProjects - HTTP Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("GraphQL Projects Error (Status \(httpResponse.statusCode)): \(errorData)")
            }
            throw APIError.invalidResponse
        }
        
        // Debug: print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("GraphQL Projects Raw Response: \(responseString.prefix(500))...")
        }
        
        // Parse GraphQL response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("GraphQL Projects Response (raw): \(errorData)")
            }
            throw APIError.decodingError
        }
        
        // Check for GraphQL errors first
        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            print("GraphQL Errors: \(errors)")
            throw APIError.decodingError
        }
        
        // Log the full response for debugging
        print("GraphQL Projects Full Response: \(json)")
        
        // Check for GraphQL errors first
        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            print("GraphQL Errors: \(errors)")
            for error in errors {
                if let message = error["message"] as? String {
                    print("Error message: \(message)")
                }
            }
            throw APIError.authenticationFailed
        }
        
        guard let dataDict = json["data"] as? [String: Any] else {
            print("No 'data' key in response")
            throw APIError.decodingError
        }
        
        // Check if viewer is null (authentication issue)
        if dataDict["viewer"] == nil || (dataDict["viewer"] as? NSNull) != nil {
            print("Viewer is null - authentication may have failed")
            print("Full data dict: \(dataDict)")
            throw APIError.authenticationFailed
        }
        
        guard let viewer = dataDict["viewer"] as? [String: Any] else {
            print("Viewer is not a dictionary in data: \(dataDict)")
            throw APIError.decodingError
        }
        
        guard let projects = viewer["projects"] as? [String: Any] else {
            print("No 'projects' key in viewer: \(viewer)")
            throw APIError.decodingError
        }
        
        guard let edges = projects["edges"] as? [[String: Any]] else {
            print("No 'edges' key in projects: \(projects)")
            throw APIError.decodingError
        }
        
        print("Found \(edges.count) project edges")
        
        var projectsList: [WandbProject] = []
        for (index, edge) in edges.enumerated() {
            print("Processing edge \(index): \(edge)")
            guard let node = edge["node"] as? [String: Any] else {
                print("Edge \(index) has no 'node' key")
                continue
            }
            
            print("Node data: \(node)")
            
            guard let id = node["id"] as? String,
                  let name = node["name"] as? String else {
                print("Node \(index) missing id or name")
                continue
            }
            
            // entityName might be optional or named differently
            let entityName = node["entityName"] as? String ?? entity
            let createdAt = node["createdAt"] as? String
            
            projectsList.append(WandbProject(
                id: id,
                name: name,
                entity: entityName,
                createdAt: createdAt
            ))
        }
        
        print("Successfully parsed \(projectsList.count) projects")
        return projectsList
    }
    
    // Fetch runs for a project using GraphQL
    func fetchRuns(entity: String, project: String, apiKey: String) async throws -> [WandbRun] {
        guard let url = URL(string: "\(baseURL)/graphql") else {
            throw APIError.invalidURL
        }
        
        // GraphQL query to fetch runs for a specific project
        let graphQLQuery = """
        query($entityName: String!, $projectName: String!) {
            project(entityName: $entityName, name: $projectName) {
                runs(order: "-createdAt") {
                    edges {
                        node {
                            id
                            name
                            state
                            createdAt
                        }
                    }
                }
            }
        }
        """
        
        let requestBody: [String: Any] = [
            "query": graphQLQuery,
            "variables": [
                "entityName": entity,
                "projectName": project
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw APIError.invalidURL
        }
        
        let authHeader = createAuthHeader(apiKey: apiKey)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Debug: verify auth header is set
        if request.value(forHTTPHeaderField: "Authorization") == nil {
            print("ERROR: Authorization header not set!")
        } else {
            let headerValue = request.value(forHTTPHeaderField: "Authorization")!
            print("Authorization header set: \(String(headerValue.prefix(20)))...")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("GraphQL Runs Error: \(errorData)")
            }
            throw APIError.invalidResponse
        }
        
        // Parse GraphQL response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = json["data"] as? [String: Any],
              let projectData = dataDict["project"] as? [String: Any],
              let runs = projectData["runs"] as? [String: Any],
              let edges = runs["edges"] as? [[String: Any]] else {
            throw APIError.decodingError
        }
        
        var runsList: [WandbRun] = []
        for edge in edges {
            if let node = edge["node"] as? [String: Any],
               let id = node["id"] as? String,
               let name = node["name"] as? String,
               let state = node["state"] as? String {
                let createdAt = node["createdAt"] as? String
                runsList.append(WandbRun(
                    id: id,
                    name: name,
                    state: state,
                    config: nil,
                    summary: nil,
                    createdAt: createdAt
                ))
            }
        }
        
        return runsList
    }
    
    // Fetch metrics for a specific run using GraphQL
    func fetchRunMetrics(entity: String, project: String, runId: String, apiKey: String) async throws -> [WandbMetric] {
        guard let url = URL(string: "\(baseURL)/graphql") else {
            throw APIError.invalidURL
        }
        
        // GraphQL query to fetch run history (same as wandview)
        // Note: runId should be the run's name, not the ID
        let graphQLQuery = """
        query($runId: String!, $projectName: String!, $entityName: String!) {
            project(name: $projectName, entityName: $entityName) {
                run(name: $runId) {
                    history
                }
            }
        }
        """
        
        print("fetchRunMetrics - entity: \(entity), project: \(project), runId: \(runId)")
        
        let requestBody: [String: Any] = [
            "query": graphQLQuery,
            "variables": [
                "runId": runId,
                "projectName": project,
                "entityName": entity
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw APIError.invalidURL
        }
        
        let authHeader = createAuthHeader(apiKey: apiKey)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Debug: verify auth header is set
        if request.value(forHTTPHeaderField: "Authorization") == nil {
            print("ERROR: Authorization header not set!")
        } else {
            let headerValue = request.value(forHTTPHeaderField: "Authorization")!
            print("Authorization header set: \(String(headerValue.prefix(20)))...")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("GraphQL Metrics Error: \(errorData)")
            }
            throw APIError.invalidResponse
        }
        
        // Debug: print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("fetchRunMetrics - Raw Response (first 1000 chars): \(responseString.prefix(1000))")
        }
        
        // Parse GraphQL response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("ERROR: Failed to parse JSON response")
            throw APIError.decodingError
        }
        
        // Check for GraphQL errors
        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            print("GraphQL Errors in metrics: \(errors)")
            throw APIError.decodingError
        }
        
        guard let dataDict = json["data"] as? [String: Any] else {
            print("ERROR: No 'data' key in response: \(json)")
            throw APIError.decodingError
        }
        
        guard let projectData = dataDict["project"] as? [String: Any] else {
            print("ERROR: No 'project' key in data: \(dataDict)")
            throw APIError.decodingError
        }
        
        // Check if run is null (run might not exist)
        if projectData["run"] == nil || (projectData["run"] as? NSNull) != nil {
            print("WARNING: Run is null - run might not exist")
            return [] // Return empty metrics if run doesn't exist
        }
        
        guard let runData = projectData["run"] as? [String: Any] else {
            print("ERROR: 'run' is not a dictionary: \(projectData)")
            throw APIError.decodingError
        }
        
        // History might be null or empty
        guard let history = runData["history"] as? [Any] else {
            print("WARNING: History is null or not an array. Run data: \(runData)")
            return [] // Return empty metrics if no history
        }
        
        print("fetchRunMetrics - Found \(history.count) history entries")
        
        // History is an array of JSON strings, need to parse each one
        var parsedHistory: [[String: Any]] = []
        for (index, item) in history.enumerated() {
            if let jsonString = item as? String {
                if let jsonData = jsonString.data(using: .utf8),
                   let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    parsedHistory.append(parsed)
                } else {
                    print("WARNING: Failed to parse history entry \(index): \(jsonString.prefix(100))")
                }
            } else {
                // History might already be parsed as dictionaries
                if let dict = item as? [String: Any] {
                    parsedHistory.append(dict)
                } else {
                    print("WARNING: History entry \(index) is neither string nor dict: \(type(of: item))")
                }
            }
        }
        
        print("fetchRunMetrics - Parsed \(parsedHistory.count) history entries")
        return parseMetrics(from: parsedHistory)
    }
    
    private func parseMetrics(from history: [[String: Any]]) -> [WandbMetric] {
        var metrics: [String: (steps: [Int], values: [Double])] = [:]
        
        for (index, entry) in history.enumerated() {
            for (key, value) in entry {
                if key == "_step" || key == "_runtime" || key == "_timestamp" {
                    continue
                }
                
                if let doubleValue = value as? Double {
                    if metrics[key] == nil {
                        metrics[key] = (steps: [], values: [])
                    }
                    metrics[key]?.steps.append(index)
                    metrics[key]?.values.append(doubleValue)
                } else if let intValue = value as? Int {
                    if metrics[key] == nil {
                        metrics[key] = (steps: [], values: [])
                    }
                    metrics[key]?.steps.append(index)
                    metrics[key]?.values.append(Double(intValue))
                }
            }
        }
        
        return metrics.map { key, data in
            WandbMetric(id: key, name: key, values: data.values, steps: data.steps)
        }
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case authenticationFailed
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed:
            return "Authentication failed"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

struct ProjectsResponse: Codable {
    let projects: [WandbProject]
}

struct RunsResponse: Codable {
    let runs: [WandbRun]
}
