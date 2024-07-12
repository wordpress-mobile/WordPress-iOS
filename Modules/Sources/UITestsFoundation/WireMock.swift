import Foundation

public class WireMock {

    public static func URL() -> Foundation.URL {
        let host = ProcessInfo().environment["WIREMOCK_HOST"] ?? "localhost"
        let port = ProcessInfo().environment["WIREMOCK_PORT"] ?? "8282"
        return Foundation.URL(string: "http://\(host):\(port)/")!
    }

    public static func setUpScenario(scenario: String) async throws {
        try await resetScenario(scenario: scenario)

        _ = try await fetchScenarios()
    }

    private static func fetchScenarios() async throws -> [String: Any] {
        let (data, _) = try await URLSession.shared.data(from: Foundation.URL(string: "\(WireMock.URL())__admin/scenarios")!)

        guard let scenarios = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(
                domain: "org.wordpress.UITestsFoundation",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not deserialized WireMock JSON response."]
            )
        }

        return scenarios
    }

    public static func resetScenario(scenario: String) async throws {
        var request = URLRequest(url: Foundation.URL(string: "\(WireMock.URL())__admin/scenarios/\(scenario)/state")!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data()

        _ = try await URLSession.shared.data(for: request)
    }
}
