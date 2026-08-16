import SwiftData

@Model
final class StoredFood {
    @Attribute(.unique) var name: String
    var caloriesPerGram: Double

    init(name: String, caloriesPerGram: Double) {
        self.name = name
        self.caloriesPerGram = caloriesPerGram
    }
}

