import Foundation

/// Remote type to fetch the user's IP Location using the public `geo` API.
///
public final class IPLocationRemote {
    private enum Constants {
        static let jsonDecoder = JSONDecoder()
    }

    private let urlSession: URLSession

    public init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }

    /// Fetches the country code from the device ip.
    ///
    public func fetchIPCountryCode(completion: @escaping (Result<String, Error>) -> Void) {
        let url = WordPressComOAuthClient.WordPressComOAuthDefaultApiBaseURL.appendingPathComponent("geo/")

        let request = URLRequest(url: url)
        let task = urlSession.dataTask(with: request) { data, _, error in
            guard let data else {
                completion(.failure(IPLocationError.requestFailure(error)))
                return
            }

            do {
                let result = try Constants.jsonDecoder.decode(RemoteIPCountryCode.self, from: data)
                completion(.success(result.countryCode))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

public extension IPLocationRemote {
    enum IPLocationError: Error {
        case requestFailure(Error?)
    }
}

public struct RemoteIPCountryCode: Decodable {
    enum CodingKeys: String, CodingKey {
        case countryCode = "country_short"
    }

    let countryCode: String
}
