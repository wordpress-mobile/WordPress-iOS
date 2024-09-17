import Foundation

enum ReaderNavigationPath: Hashable {
    case discover
    case likes
    case search
    case post(postID: Int, siteID: Int, isFeed: Bool = false)
}
