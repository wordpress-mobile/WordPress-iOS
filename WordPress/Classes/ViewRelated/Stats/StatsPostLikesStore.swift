import Foundation
import JetpackStats
import WordPressData

/// Bridges likers fetched by the JetpackStats package into the app's shared
/// `LikeUser` cache, so the Likes list screen (`LikesListController`) can
/// seed itself from cache instead of starting empty.
struct StatsPostLikesStore: PostLikesStore {
    let siteID: Int64

    func storeLikes(_ likes: [PostLikeSeed], totalCount: Int, forPost postID: Int) async {
        let seeds = likes.map { like in
            LikeUserSeed(
                userID: Int64(like.userID),
                displayName: like.displayName,
                username: like.username ?? "",
                avatarUrl: like.avatarURL ?? "",
                dateLikedString: like.dateLikedString ?? ""
            )
        }
        let siteID = self.siteID
        let postID = Int64(postID)
        await withCheckedContinuation { continuation in
            ContextManager.shared.performAndSave(
                { context in
                    // A confirmed zero-like result clears the post's cache so the
                    // Likes list cannot seed stale likers under a "0 likes" title.
                    // A positive total upserts the partial first page without
                    // purging a possibly fuller previously cached list.
                    if totalCount == 0 {
                        LikeUserHelper.deleteLikes(forPost: postID, siteID: siteID, in: context)
                    } else {
                        LikeUserHelper.upsert(seeds: seeds, siteID: siteID, postID: postID, in: context)
                    }
                },
                completion: {
                    continuation.resume()
                },
                on: .main
            )
        }
    }
}
