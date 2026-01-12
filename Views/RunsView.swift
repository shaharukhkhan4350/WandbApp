//
//  RunsView.swift
//  WandbApp
//
//  View displaying runs for a project with training graphs
//

import SwiftUI

struct RunsView: View {
    @EnvironmentObject var viewModel: ProjectsViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    let project: WandbProject?
    
    @StateObject private var runsViewModel = RunsViewModel()
    @State private var selectedRun: WandbRun?
    
    init(project: WandbProject? = nil) {
        self.project = project
    }
    
    var body: some View {
        NavigationView {
            Group {
                if runsViewModel.isLoading {
                    ProgressView("Loading runs...")
                } else if runsViewModel.runs.isEmpty && !runsViewModel.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No runs found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(runsViewModel.runs) { run in
                        NavigationLink(destination: MetricsView(run: run, project: project)
                            .environmentObject(authManager)) {
                            RunRow(run: run)
                        }
                    }
                }
            }
            .navigationTitle(project?.name ?? "Runs")
            .refreshable {
                if let project = project {
                    await runsViewModel.fetchRuns(
                        entity: project.entity,
                        project: project.name,
                        apiKey: authManager.apiKey
                    )
                }
            }
            .onAppear {
                if let project = project {
                    runsViewModel.setCredentials(
                        apiKey: authManager.apiKey,
                        entity: authManager.entity
                    )
                    Task {
                        await runsViewModel.fetchRuns(
                            entity: project.entity,
                            project: project.name,
                            apiKey: authManager.apiKey
                        )
                    }
                }
            }
        }
    }
}

struct RunRow: View {
    let run: WandbRun
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(run.name)
                .font(.headline)
            HStack {
                Text(run.state)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(stateColor(for: run.state).opacity(0.2))
                    .foregroundColor(stateColor(for: run.state))
                    .cornerRadius(4)
                
                Spacer()
                
                if let createdAt = run.createdAt {
                    Text(formatDate(createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func stateColor(for state: String) -> Color {
        switch state.lowercased() {
        case "running":
            return .blue
        case "finished":
            return .green
        case "failed":
            return .red
        default:
            return .gray
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}
