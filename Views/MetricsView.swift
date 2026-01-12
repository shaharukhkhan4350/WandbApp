//
//  MetricsView.swift
//  WandbApp
//
//  View displaying training metrics as graphs
//

import SwiftUI
import Charts

struct MetricsView: View {
    let run: WandbRun
    let project: WandbProject?
    
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var metricsViewModel = MetricsViewModel()
    @State private var selectedMetric: WandbMetric?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Run Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(run.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Label(run.state, systemImage: "circle.fill")
                            .font(.caption)
                            .foregroundColor(stateColor(for: run.state))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                if metricsViewModel.isLoading {
                    ProgressView("Loading metrics...")
                        .frame(height: 200)
                } else if metricsViewModel.metrics.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No metrics available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 200)
                } else {
                    // Metrics List
                    ForEach(metricsViewModel.metrics) { metric in
                        MetricChartView(metric: metric)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Training Metrics")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            if let project = project {
                await metricsViewModel.fetchMetrics(
                    entity: project.entity,
                    project: project.name,
                    runId: run.name, // Use run.name, not run.id for GraphQL query
                    apiKey: authManager.apiKey
                )
            }
        }
        .onAppear {
            if let project = project {
                metricsViewModel.setCredentials(
                    apiKey: authManager.apiKey,
                    entity: authManager.entity
                )
                Task {
                    await metricsViewModel.fetchMetrics(
                        entity: project.entity,
                        project: project.name,
                        runId: run.name, // Use run.name, not run.id for GraphQL query
                        apiKey: authManager.apiKey
                    )
                }
            }
        }
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
}

struct MetricChartView: View {
    let metric: WandbMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(metric.name)
                .font(.headline)
                .padding(.horizontal)
            
            Chart(metric.dataPoints, id: \.step) { point in
                LineMark(
                    x: .value("Step", point.step),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(.purple)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Step", point.step),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .purple.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .padding(.vertical, 8)
    }
}
