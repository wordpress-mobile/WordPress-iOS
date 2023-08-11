import Foundation

public class WireMock {

    public static func URL() -> Foundation.URL {
        let host = ProcessInfo().environment["WIREMOCK_HOST"] ?? "localhost"
        let port = ProcessInfo().environment["WIREMOCK_PORT"] ?? "8282"
        return Foundation.URL(string: "http://\(host):\(port)/")!
    }

    public static func fetchScenarios(completion: @escaping ([String: Any]?, Error?) -> Void) {
        let url = Foundation.URL(string: "\(WireMock.URL())__admin/scenarios")!

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                    completion(json, nil)
                }
            } catch {
                completion(nil, error)
            }
        }

        task.resume()
    }

    public static func resetScenario(scenario: String) {
        let url = Foundation.URL(string: "\(WireMock.URL())__admin/scenarios/\(scenario)/state")!

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data()

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("Error resetting scenarios: \(error!)")
                return
            }
        }

        task.resume()
    }
}
