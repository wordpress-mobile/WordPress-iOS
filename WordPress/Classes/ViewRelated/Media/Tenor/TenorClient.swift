import Foundation

typealias TenorResponseBlock = (Swift.Result<TenorResponse, Error>) -> ()

enum TenorError: Error {
    case wrongDataFormat
    case wrongUrl
}

class TenorClient {
    static let endpoint = "https://api.tenor.com/v1/search"
    private let session = URLSession(configuration: .default)
    private let tenorAppId: String

    // Parameter is only used during testing
    init(tenorAppId: String? = nil) {
        self.tenorAppId = tenorAppId ?? ApiCredentials.tenorAppId()
    }

    func search(_ query: String, pos: Int, limit: Int, completion: @escaping TenorResponseBlock) {
        var components = URLComponents(string: TenorClient.endpoint)

        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: tenorAppId),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "pos", value: "\(pos)")
        ]

        guard let url = components?.url else {
            completion(.failure(TenorError.wrongUrl))
            return
        }

        session.dataTask(with: url) { (data, response, error) in
            if let data = data {
                if let response = try? JSONDecoder().decode(TenorResponse.self, from: data) {
                    completion(.success(response))
                } else {
                    completion(.failure(TenorError.wrongDataFormat))
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}
