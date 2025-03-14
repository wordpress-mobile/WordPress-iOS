import Foundation
import WordPressShared

enum ReaderNavigationPath: Hashable {
    case recent
    case discover
    case likes
    case search
    case subscriptions
    case post(postID: Int, siteID: Int, isFeed: Bool = false)
    case postURL(URL)
    case topic(ReaderAbstractTopic)
    case tag(String)
}

extension ReaderNavigationPath {
    static func makeWithTagName(_ name: String) -> ReaderNavigationPath {
        let remote = ReaderTopicServiceRemote(wordPressComRestApi: WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress()))
        let slug = remote.slug(forTopicName: name) ?? name.lowercased()
        return ReaderNavigationPath.tag(slug)
    }
}
