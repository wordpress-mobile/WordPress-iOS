import Foundation
@preconcurrency import WordPressKit

/// A single liker in the shape the app's shared likes cache expects.
///
/// Built directly from the API response so the cache receives full-fidelity
/// data even though the stats UI renders only name and avatar: the Likes list
/// cell shows an `@username` subtitle, and the cache sorts and pages by the
/// parsed like date, so dropping either field here would degrade seeded rows.
/// The date is kept as the server-formatted string because the cache stores
/// that string verbatim as its paging cursor.
public struct PostLikeSeed: Equatable, Sendable {
    public let userID: Int
    public let displayName: String
    public let username: String?
    public let avatarURL: String?
    public let dateLikedString: String?

    public init(
        userID: Int,
        displayName: String,
        username: String?,
        avatarURL: String?,
        dateLikedString: String?
    ) {
        self.userID = userID
        self.displayName = displayName
        self.username = username
        self.avatarURL = avatarURL
        self.dateLikedString = dateLikedString
    }
}

extension PostLikeSeed {
    init(remoteUser: RemoteLikeUser) {
        self.init(
            userID: remoteUser.userID?.intValue ?? 0,
            displayName: remoteUser.displayName ?? remoteUser.username ?? "",
            username: remoteUser.username,
            avatarURL: remoteUser.avatarURL,
            dateLikedString: remoteUser.dateLiked
        )
    }
}

/// App-injected sink that persists likers fetched by Post Stats into the
/// app's shared likes cache, so the Likes list screen can seed itself from
/// cache instead of starting empty. The package deliberately knows nothing
/// about the cache's implementation; `nil` (previews, mocks) disables seeding.
public protocol PostLikesStore: Sendable {
    /// Persists the likers fetched by Post Stats for a post.
    ///
    /// `totalCount` is the post's authoritative like count from the same fetch.
    /// When it is `0` the store must clear any cached likers for the post: Post
    /// Stats only ever seeds the first page, so a plain upsert of the empty
    /// `likes` would leave stale rows that the Likes list would show under a
    /// "0 likes" title (including offline, where its own refresh cannot run).
    /// A positive `totalCount` upserts the partial seeds without purging.
    func storeLikes(_ likes: [PostLikeSeed], totalCount: Int, forPost postID: Int) async
}
