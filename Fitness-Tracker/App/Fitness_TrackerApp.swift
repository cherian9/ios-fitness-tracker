
import SwiftUI
import SwiftData

@main
struct Fitness_TrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [StoredFood.self, DailyWeightEntry.self])
    }
}
