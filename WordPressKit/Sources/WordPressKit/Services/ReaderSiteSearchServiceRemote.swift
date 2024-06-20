import Foundation
import WordPressShared

public class ReaderSiteSearchServiceRemote: ServiceRemoteWordPressComREST {

    public enum ResponseError: Error {
        case decodingFailure
    }

    /// Searches Reader for sites matching the specified query.
    ///
    /// - Parameters:
    ///     - query: A search string to match
    ///     - offset: The first N results to skip when returning results.
    ///     - count: Number of objects to retrieve.
    ///     - success: Closure to be executed on success. Is passed an array of
    ///                ReaderFeeds, a boolean indicating if there's more results
    ///                to fetch, and a total feed count.
    ///     - failure: Closure to be executed on error.
    ///
    public func performSearch(_ query: String,
                              offset: Int = 0,
                              count: Int,
                              success: @escaping (_ results: [ReaderFeed], _ hasMore: Bool, _ feedCount: Int) -> Void,
                              failure: @escaping (Error) -> Void) {
        let endpoint = "read/feed"
        let path = self.path(forEndpoint: endpoint, withVersion: ._1_1)
        let parameters: [String: AnyObject] = [
            "number": count as AnyObject,
            "offset": offset as AnyObject,
            "exclude_followed": false as AnyObject,
            "sort": "relevance" as AnyObject,
            "meta": "site" as AnyObject,
            "q": query as AnyObject
        ]

        wordPressComRESTAPI.get(path,
                                parameters: parameters,
                                success: { response, _ in
                                    do {
                                        let (results, total) = try self.mapSearchResponse(response)
                                        let hasMore = total > (offset + count)
                                        success(results, hasMore, total)
                                    } catch {
                                        failure(error)
                                    }
        }, failure: { error, _ in
            WPKitLogError("\(error)")
            failure(error)
        })
    }
}

private extension ReaderSiteSearchServiceRemote {

    func mapSearchResponse(_ response: Any) throws -> ([ReaderFeed], Int) {
        do {
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: response, options: [])
            let envelope = try decoder.decode(ReaderFeedEnvelope.self, from: data)

            // Filter out any feeds that don't have either a feed ID or a blog ID
            let feeds = envelope.feeds.filter({ $0.feedID != nil || $0.blogID != nil })
            return (feeds, envelope.total)
        } catch {
            WPKitLogError("\(error)")
            WPKitLogDebug("Full response: \(response)")
            throw ReaderSiteSearchServiceRemote.ResponseError.decodingFailure
        }
    }
}

/// ReaderFeedEnvelope
/// The Reader feed search endpoint returns feeds in a key named `feeds` key.
/// This entity allows us to do parse that and the total feed count using JSONDecoder.
///
private struct ReaderFeedEnvelope: Decodable {
    let feeds: [ReaderFeed]
    let total: Int

    private enum CodingKeys: String, CodingKey {
        case feeds = "feeds"
        case total = "total"
    }
}
