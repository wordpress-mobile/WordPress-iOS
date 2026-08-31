import Foundation
import WordPressAPI
@testable import WordPressComments

struct FakeServiceError: Error {}

@MainActor
final class FakeCommentsService: CommentsServiceProtocol {
    var queuedResults: [Result<CommentsPage, Error>] = []
    private(set) var requests: [(filter: CommentsListFilter, nextPage: CommentsPageToken?)] = []

    /// Per-id results take precedence; `fetchCommentResult` is the fallback.
    var fetchCommentResultsByID: [Int64: Result<CommentDetail, Error>] = [:]
    var fetchCommentResult: Result<CommentDetail, Error>?
    private(set) var fetchCommentInvocations: [(id: Int64, allowsEditContext: Bool)] = []

    func listComments(filter: CommentsListFilter, nextPage: CommentsPageToken?) async throws -> CommentsPage {
        requests.append((filter, nextPage))
        guard !queuedResults.isEmpty else {
            throw FakeServiceError()
        }
        return try queuedResults.removeFirst().get()
    }

    func fetchComment(id: Int64, allowsEditContext: Bool) async throws -> CommentDetail {
        fetchCommentInvocations.append((id, allowsEditContext))
        guard let result = fetchCommentResultsByID[id] ?? fetchCommentResult else { throw FakeServiceError() }
        return try result.get()
    }
}

func makePage(items: [CommentListItem], hasNext: Bool) -> CommentsPage {
    CommentsPage(
        items: items,
        nextPage: hasNext ? CommentsPageToken(params: CommentListParams(page: 2)) : nil
    )
}
