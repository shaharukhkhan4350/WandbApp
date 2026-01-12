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
    @State private var selectedStep: Int?
    @State private var selectedValue: Double?
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(metric.name)
                    .font(.headline)
                Spacer()
                Button(action: { isExpanded = true }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            ChartContainer(metric: metric, selectedStep: $selectedStep, selectedValue: $selectedValue)
                .frame(height: 200)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .padding(.vertical, 8)
        .fullScreenCover(isPresented: $isExpanded) {
            FullScreenMetricView(metric: metric, isPresented: $isExpanded)
        }
    }
}

struct FullScreenMetricView: View {
    let metric: WandbMetric
    @Binding var isPresented: Bool
    @State private var selectedStep: Int?
    @State private var selectedValue: Double?
    
    var body: some View {
        NavigationView {
            VStack {
                ChartContainer(metric: metric, selectedStep: $selectedStep, selectedValue: $selectedValue)
                    .padding()
            }
            .navigationTitle(metric.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct ChartContainer: View {
    let metric: WandbMetric
    @Binding var selectedStep: Int?
    @Binding var selectedValue: Double?
    
    var body: some View {
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
            
            if let selStep = selectedStep, let selVal = selectedValue {
                RuleMark(
                    x: .value("Selected Step", selStep)
                )
                .foregroundStyle(Color.gray.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                .annotation(position: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Step: \(selStep)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Value: \(String(format: "%.4f", selVal))")
                            .font(.caption.bold())
                            .foregroundColor(.primary)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }
                
                PointMark(
                    x: .value("Selected Step", selStep),
                    y: .value("Selected Value", selVal)
                )
                .foregroundStyle(.purple)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x
                                if let step = proxy.value(atX: x, as: Int.self) {
                                    // Find closest data point
                                    if let closest = metric.dataPoints.min(by: { abs($0.step - step) < abs($1.step - step) }) {
                                        selectedStep = closest.step
                                        selectedValue = closest.value
                                    }
                                }
                            }
                            .onEnded { _ in
                                selectedStep = nil
                                selectedValue = nil
                            }
                    )
            }
        }
    }
}
