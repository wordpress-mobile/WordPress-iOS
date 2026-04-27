import Foundation
import WordPressData
import WordPressShared
import WordPressKit

enum ReaderNavigationPath: Hashable {
    case recent
    case discover
    /// A Reader stream identified by key, e.g. the key used by `/read/streams/:stream_key`.
    /// Resolves to a matching Discover channel when available, otherwise falls back to a tag.
    case discoverStream(key: String, queryParameters: [String: String]?)
    case likes
    case search
    case subscriptions
    case post(postID: Int, siteID: Int, isFeed: Bool = false)
    case postURL(URL)
    case topic(ReaderAbstractTopic)
    case tag(String)
    case site(siteID: Int, isFeed: Bool)
}

extension ReaderNavigationPath {
    static func makeWithTagName(_ name: String) -> ReaderNavigationPath {
        let remote = ReaderTopicServiceRemote(wordPressComRestApi: WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress()))
        let slug = remote.slug(forTopicName: name) ?? name.lowercased()
        return ReaderNavigationPath.tag(slug)
    }
}
