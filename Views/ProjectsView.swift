//
//  ProjectsView.swift
//  WandbApp
//
//  View displaying list of wandb projects
//

import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var viewModel: ProjectsViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedProject: WandbProject?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading projects...")
                } else if viewModel.projects.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No projects found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.projects) { project in
                        NavigationLink(destination: RunsView(project: project)) {
                            ProjectRow(project: project)
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .refreshable {
                await viewModel.fetchProjects()
            }
            .onAppear {
                // Ensure credentials are set before fetching
                if viewModel.apiKey.isEmpty {
                    viewModel.setCredentials(
                        apiKey: authManager.apiKey,
                        entity: authManager.entity
                    )
                }
                if viewModel.projects.isEmpty {
                    Task {
                        await viewModel.fetchProjects()
                    }
                }
            }
        }
    }
}

struct ProjectRow: View {
    let project: WandbProject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.name)
                .font(.headline)
            Text(project.entity)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
