import Foundation
import WordPressData
@preconcurrency import WordPressKit
import WordPressShared

protocol CustomPostViewCountFetching: Sendable {
    /// All-time views of one post.
    func fetchViewCount(postID: Int64) async throws -> Int
}

/// Fetches view counts from the WordPress.com stats endpoint.
///
/// Stats need a WordPress.com site ID and a signed-in account, so a
/// self-hosted site reached only over an application password gets no
/// fetcher, and its rows show comment counts alone.
struct StatsViewCountFetcher: CustomPostViewCountFetching {
    private let remote: StatsServiceRemoteV2

    @MainActor
    init?(blog: Blog) {
        guard
            blog.supports(.stats),
            let siteID = blog.dotComID?.intValue,
            let authToken = blog.account?.authToken,
            let timeZone = blog.timeZone
        else {
            return nil
        }
        let api = WordPressComRestApi.defaultApi(oAuthToken: authToken, userAgent: WPUserAgent.wordPress())
        remote = StatsServiceRemoteV2(wordPressComRestApi: api, siteID: siteID, siteTimezone: timeZone)
    }

    func fetchViewCount(postID: Int64) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            remote.getDetails(forPostID: Int(postID)) { details, error in
                if let details {
                    continuation.resume(returning: details.totalViewsCount)
                } else {
                    continuation.resume(throwing: error ?? URLError(.badServerResponse))
                }
            }
        }
    }
}
