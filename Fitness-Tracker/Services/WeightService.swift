import Foundation

class WeightService {

    private let baseURL = "http://127.0.0.1:3000"

    func getWeights() async throws -> [Weight] {

        let start = Date()

        guard let url = URL(string: "\(baseURL)/weights") else {
            throw URLError(.badURL)
        }

        print("URL:", url)
        print("Sending request...")

        let (data, response) = try await URLSession.shared.data(from: url)

        print(
            "URLSession took:",
            Date().timeIntervalSince(start),
            "seconds"
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("Status code:", httpResponse.statusCode)

        let weights = try JSONDecoder().decode(
            [Weight].self,
            from: data
        )

        print("Decoding finished")

        return weights
    }
     func addWeight(
        weight: Double,
        date: Date,
        userId: Int
    ) async throws -> Weight {
        
        guard let url = URL(
            string: "\(baseURL)/weights"
        ) else {
            throw URLError(.badURL)
        }
        
        let formatter = ISO8601DateFormatter()
        
        let body: [String: Any] = [
            "weight": weight,
            "date": formatter.string(from: date),
            "userId": userId
        ]
        
        let jsonData = try JSONSerialization.data(
            withJSONObject: body
        )
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        request.httpBody = jsonData
        
        let (data, response) =
            try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("POST status:", httpResponse.statusCode)

        print(
            "POST response:",
            String(data: data, encoding: .utf8) ?? "No response"
        )

        guard httpResponse.statusCode == 201 else {

            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(
            Weight.self,
            from: data
        )    }
}
