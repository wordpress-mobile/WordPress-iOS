import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

/// Counts the comments on posts for the redesigned posts list.
///
/// Reads the plain WP REST comments endpoint rather than WordPress.com stats,
/// so it works the same on a self-hosted site reached over an application
/// password as it does anywhere else. Counts approved comments, matching the
/// number wp-admin shows against a post.
struct CustomPostCommentCountFetcher: Sendable {
    /// One page of a comments listing, reduced to what counting needs.
    struct Page: Sendable {
        /// The `post` field of every comment returned.
        let postIDs: [PostId]
        /// The `X-WP-Total` header, when the site sent one.
        let total: UInt32?
    }

    typealias Request = @Sendable (CommentListParams) async throws -> Page

    private let request: Request

    init(client: WordPressClient) {
        self.init { params in
            let response = try await client.api.comments.filterListWithViewContext(params: params, fields: [.id, .post])
            return Page(postIDs: response.data.compactMap(\.post), total: response.headerMap.wpTotal())
        }
    }

    init(request: @escaping Request) {
        self.request = request
    }

    /// Comment counts for `postIDs`, keyed by post id.
    ///
    /// Normally one request for the whole batch. Posts absent from the response
    /// have no comments and come back as zero. When the batch has more comments
    /// than one page holds, counting the page would undercount, so every post
    /// is asked for individually instead; a post whose request fails is omitted.
    func fetchCommentCounts(for postIDs: [Int64]) async throws -> [Int64: Int] {
        guard !postIDs.isEmpty else { return [:] }

        let page = try await request(CommentListParams(perPage: Constants.batchPageSize, post: postIDs))
        if let total = page.total, total > page.postIDs.count {
            return await fetchOneByOne(postIDs)
        }
        return tally(postIDs, commentPostIDs: page.postIDs)
    }

    private func tally(_ postIDs: [Int64], commentPostIDs: [PostId]) -> [Int64: Int] {
        var counts = Dictionary(uniqueKeysWithValues: Set(postIDs).map { ($0, 0) })
        for postID in commentPostIDs where counts[postID] != nil {
            counts[postID, default: 0] += 1
        }
        return counts
    }

    /// Asks per post for a single comment and reads the count out of the total
    /// header, so the body stays small and the number is exact.
    private func fetchOneByOne(_ postIDs: [Int64]) async -> [Int64: Int] {
        await withTaskGroup(of: (Int64, Int?).self) { group in
            for postID in Set(postIDs) {
                group.addTask {
                    let page = try? await request(CommentListParams(perPage: 1, post: [postID]))
                    return (postID, page?.total.map(Int.init))
                }
            }
            var counts: [Int64: Int] = [:]
            for await (postID, count) in group {
                if let count {
                    counts[postID] = count
                }
            }
            return counts
        }
    }

    private enum Constants {
        /// WP REST caps a page at 100, which is also the most a batch can count without paging.
        static let batchPageSize: UInt32 = 100
    }
}
