import Foundation

struct Weight: Codable, Identifiable {
    let id: Int
    let weight: Double
    let date: String
    let userId: Int

    enum CodingKeys: String, CodingKey {
        case id
        case weight
        case date
        case userId = "user_id"
    }

    var dateValue: Date? {
        ISO8601DateFormatter().date(from: date)
    }
}
