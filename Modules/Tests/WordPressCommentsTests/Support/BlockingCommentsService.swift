import Foundation
import WordPressAPI
@testable import WordPressComments

/// A service whose calls suspend until the test resolves them by index, so a
/// test can interleave in-flight calls deterministically (for example a
/// `loadMore` with a `refresh`, or two detail appearances).
@MainActor
final class BlockingCommentsService: CommentsServiceProtocol {
    private var continuations: [CheckedContinuation<CommentsPage, Error>] = []
    private var fetchContinuations: [CheckedContinuation<CommentDetail, Error>] = []
    private(set) var callCount = 0
    private(set) var fetchCommentInvocations: [(id: Int64, allowsEditContext: Bool)] = []

    func listComments(filter: CommentsListFilter, nextPage: CommentsPageToken?) async throws -> CommentsPage {
        callCount += 1
        return try await withCheckedThrowingContinuation { continuations.append($0) }
    }

    func fetchComment(id: Int64, allowsEditContext: Bool) async throws -> CommentDetail {
        fetchCommentInvocations.append((id, allowsEditContext))
        return try await withCheckedThrowingContinuation { fetchContinuations.append($0) }
    }

    func resolve(callIndex: Int, with page: CommentsPage) {
        continuations[callIndex].resume(returning: page)
    }

    func resolveFetch(callIndex: Int, with detail: CommentDetail) {
        fetchContinuations[callIndex].resume(returning: detail)
    }
}
