
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CalorieTrackerView()
                .tabItem {
                    Label("Tracker", systemImage: "fork.knife")
                }

            WeightGraphView()
                .tabItem {
                    Label("Weight", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(FitnessTheme.accent)
    }
}

