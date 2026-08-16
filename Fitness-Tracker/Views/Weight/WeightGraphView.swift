import SwiftUI
import Charts

struct WeightGraphView: View {
    
    @State private var weights: [Weight] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let weightService = WeightService()
    
    @AppStorage("goalWeight")
    private var goalWeight: Double = 0
    
    @AppStorage("hasSavedProfile")
    private var hasSavedProfile = false
    
    
    // MARK: - Load weights from backend
    
    private func loadWeights() async {
        let start = Date()
        isLoading = true
        errorMessage = nil
        
        do {
            print("Starting request...")
            
            weights = try await weightService.getWeights()
            let elapsed = Date().timeIntervalSince(start)
            print("Starting request...")
            print("Swift API request took: \(elapsed) seconds")
            print("Weights from backend:", weights)
            print("Number of weights:", weights.count)
            
        } catch {
            errorMessage = error.localizedDescription
            print("API Error:", error)
        }
        
        isLoading = false
    }
    
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            
            VStack(spacing: 20) {
                
                // MARK: Goal Weight
                
                if hasSavedProfile && goalWeight > 0 {
                    
                    HStack {
                        Text("Goal Weight")
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Text(
                            "\(String(format: "%.1f", goalWeight)) kg"
                        )
                        .foregroundStyle(FitnessTheme.accent)
                        .fontWeight(.semibold)
                    }
                    .fitnessCard()
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                
                // MARK: Loading
                
                if isLoading {
                    
                    Spacer()
                    
                    ProgressView()
                        .tint(FitnessTheme.accent)
                    
                    Text("Loading weights...")
                        .font(.subheadline)
                        .foregroundStyle(
                            FitnessTheme.secondaryText
                        )
                    
                    Spacer()
                    
                }
                
                
                // MARK: Error
                
                else if let errorMessage {
                    
                    Spacer()
                    
                    VStack(spacing: 10) {
                        
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundStyle(.red)
                        
                        Text("Could not load weights")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(
                                FitnessTheme.secondaryText
                            )
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    Spacer()
                }
                
                
                // MARK: No weights
                
                else if weights.isEmpty {
                    
                    Spacer()
                    
                    Text("No weight entries yet")
                        .font(.subheadline)
                        .foregroundStyle(
                            FitnessTheme.secondaryText
                        )
                    
                    Spacer()
                    
                }
                
                
                // MARK: Weight data
                
                else {
                    
                    // MARK: Weight Graph
                    
                    Chart {
                        
                        ForEach(weights) { entry in
                            
                            if let date = entry.dateValue {
                                
                                LineMark(
                                    x: .value(
                                        "Date",
                                        date
                                    ),
                                    y: .value(
                                        "Weight",
                                        entry.weight
                                    )
                                )
                                .foregroundStyle(
                                    FitnessTheme.accent
                                )
                                .lineStyle(
                                    StrokeStyle(
                                        lineWidth: 2.5
                                    )
                                )
                                
                                
                                PointMark(
                                    x: .value(
                                        "Date",
                                        date
                                    ),
                                    y: .value(
                                        "Weight",
                                        entry.weight
                                    )
                                )
                                .foregroundStyle(
                                    FitnessTheme.accent
                                )
                            }
                        }
                        
                        
                        // MARK: Goal Weight Line
                        
                        if goalWeight > 0 {
                            
                            RuleMark(
                                y: .value(
                                    "Goal",
                                    goalWeight
                                )
                            )
                            .foregroundStyle(
                                FitnessTheme.accentBlue
                                    .opacity(0.8)
                            )
                            .lineStyle(
                                StrokeStyle(
                                    lineWidth: 1.5,
                                    dash: [6, 4]
                                )
                            )
                            .annotation(
                                position: .top,
                                alignment: .trailing
                            ) {
                                Text("Goal")
                                    .font(.caption2)
                                    .foregroundStyle(
                                        FitnessTheme.accentBlue
                                    )
                            }
                        }
                    }
                    .chartXAxis {
                        
                        AxisMarks { _ in
                            
                            AxisGridLine(
                                stroke: StrokeStyle(
                                    lineWidth: 0.5
                                )
                            )
                            .foregroundStyle(
                                FitnessTheme.elevatedBackground
                            )
                            
                            AxisValueLabel()
                                .foregroundStyle(
                                    FitnessTheme.secondaryText
                                )
                        }
                    }
                    .chartYAxis {
                        
                        AxisMarks { _ in
                            
                            AxisGridLine(
                                stroke: StrokeStyle(
                                    lineWidth: 0.5
                                )
                            )
                            .foregroundStyle(
                                FitnessTheme.elevatedBackground
                            )
                            
                            AxisValueLabel()
                                .foregroundStyle(
                                    FitnessTheme.secondaryText
                                )
                        }
                    }
                    .frame(height: 280)
                    .padding()
                    .fitnessCard()
                    .padding(.horizontal)
                    
                    
                    // MARK: Weight History
                    
                    ScrollView {
                        
                        VStack(spacing: 12) {
                            
                            ForEach(weights) { entry in
                                
                                HStack {
                                    
                                    if let date = entry.dateValue {
                                        Text(
                                            date.formatted(
                                                date: .abbreviated,
                                                time: .omitted
                                            )
                                        )
                                        .foregroundStyle(.white)
                                    } else {
                                        Text(entry.date)
                                            .foregroundStyle(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(
                                        "\(String(format: "%.1f", entry.weight)) kg"
                                    )
                                    .foregroundStyle(
                                        FitnessTheme.accent
                                    )
                                    .fontWeight(.medium)
                                }
                                .fitnessCard()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .fitnessBackground()
            .navigationTitle("Weight")
            .toolbarBackground(
                FitnessTheme.background,
                for: .navigationBar
            )
            .toolbarBackground(
                .visible,
                for: .navigationBar
            )
        }
        .task {
            await loadWeights()
        }
    }
}
