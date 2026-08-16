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
}
