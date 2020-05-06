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
    static let contentFilter = "contentfilter"
}

// Reference: https://tenor.com/gifapi/documentation#contentfilter
enum TenorContentFilter: String {
    /// G, PG, PG-13, R rated
    case off
    /// G, PG, PG-13 rated
    case low
    /// G and PG rated
    case medium
    /// G rated
    case high
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

    /// Return a list of GIFs from Tenor for a given search query
    /// - Parameters:
    ///   - query: a search string
    ///   - limit: return up to a specified number of results (max "limit" is 50 enforced by Tenor, default is 20 if unspecified)
    ///   - position: return results starting from "position" (use it's the last "position" of the previous search, for paging purpose)
    ///   - contentFilter: specify the content safety filter level
    ///   - completion: the handler which will be called on completion
    public func search(for query: String, limit: Int = 20,
                       from position: String?,
                       contentFilter: TenorContentFilter = .high,
                       completion: @escaping TenorSearchResult) {
        assert(limit <= 50, "Tenor allows a maximum 50 images per search")

        guard let url = URL(string: EndPoints.search.rawValue) else {
            return
        }

        let params: [String: Any] = [
            SearchParams.key: config.apiKey!,
            SearchParams.searchString: query,
            SearchParams.limit: limit,
            SearchParams.position: position ?? "",
            SearchParams.contentFilter: contentFilter.rawValue,
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
                    DDLogError("Couldn't decode API response from Tenor. Required to check https://tenor.com/gifapi/documentation for breaking changes if needed")

                    completion(nil, nil, error)
                }

            case .failure(let error):
                completion(nil, nil, error)
            }
        }
    }
}
