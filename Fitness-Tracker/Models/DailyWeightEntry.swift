import Foundation
import SwiftData

@Model
final class DailyWeightEntry {
    @Attribute(.unique) var dayKey: String
    var date: Date
    var weight: Double

    init(dayKey: String, date: Date, weight: Double) {
        self.dayKey = dayKey
        self.date = date
        self.weight = weight
    }
}
