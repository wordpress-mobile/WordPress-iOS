// Encapsulates Tenor API Client to interact with Tenor

import Foundation
import Alamofire

// MARK: Search endpoint & params

private enum EndPoints: String {
    case search = "https://api.tenor.com/v1/search"
}

private struct SearchParams {
    static let key = "key"
    static let searchString = "q"
    static let limit = "limit"
    static let position = "pos"
}

// MARK: - TenorClient

private struct ClientConfig {
    var apiKey: String?
}

struct TenorClient {
    typealias TenorSearchResult = ((_ data: [TenorGIF]?, _ position: String?, _ error: Error?) -> Void)

    private var config: ClientConfig
    static var shared = TenorClient()

    private init() {
        config = ClientConfig()
    }

    static func configure(apiKey: String) {
        shared.config.apiKey = apiKey
    }

    // MARK: - Public Methods

    func search(for query: String, limit: Int = 20, from position: String?, completion: @escaping TenorSearchResult) {
        assert(limit <= 50, "Tenor allows a maximum 50 images per search")

        guard let url = URL(string: EndPoints.search.rawValue) else {
            return
        }

        let params: [String: Any] = [
            SearchParams.key: config.apiKey!,
            SearchParams.searchString: query,
            SearchParams.limit: limit,
            SearchParams.position: position ?? "",
        ]

        Alamofire.request(url, method: .get, parameters: params).responseData { response in

            switch response.result {
            case .success:
                guard let data = response.data else {
                    let error = NSError(domain: "TenorClient", code: -1, userInfo: nil)
                    completion(nil, nil, error)
                    return
                }

                do {
                    let parser = TenorResponseParser<TenorGIF>()
                    try parser.parse(data)

                    completion(parser.results ?? [], parser.next, nil)
                } catch {
                    assertionFailure("Couldn't decode API response from Tenor. Required to check https://tenor.com/gifapi/documentation for breaking changes if needed")
                    completion(nil, nil, error)
                }

            case .failure(let error):
                completion(nil, nil, error)
            }
        }
    }
}
