import Foundation
import WordPressAPI
@testable import WordPressComments

/// A service whose list, fetch, and status calls suspend until the test
/// resolves them by index, so a test can interleave in-flight calls
/// deterministically (for example a `loadMore` with a `refresh`, two detail
/// appearances, or a moderation request still in flight).
@MainActor
final class BlockingCommentsService: CommentsServiceProtocol {
    private var continuations: [CheckedContinuation<CommentsPage, Error>] = []
    private var fetchContinuations: [CheckedContinuation<CommentDetail, Error>] = []
    private var setStatusContinuations: [CheckedContinuation<CommentDetail, Error>] = []
    private(set) var setStatusInvocations: [(id: Int64, status: CommentListItem.Status)] = []
    private(set) var callCount = 0
    private(set) var fetchCommentInvocations: [(id: Int64, allowsEditContext: Bool)] = []
    /// When nil, `numberOfReplies` blocks like the other calls.
    var numberOfRepliesResult: Result<Int, Error>? = .success(0)
    private var numberOfRepliesContinuations: [CheckedContinuation<Int, Error>] = []
    private(set) var numberOfRepliesInvocations: [Int64] = []

    func listComments(filter: CommentsListFilter, nextPage: CommentsPageToken?) async throws -> CommentsPage {
        callCount += 1
        return try await withCheckedThrowingContinuation { continuations.append($0) }
    }

    func resolve(callIndex: Int, with page: CommentsPage) {
        continuations[callIndex].resume(returning: page)
    }

    func fetchComment(id: Int64, allowsEditContext: Bool) async throws -> CommentDetail {
        fetchCommentInvocations.append((id, allowsEditContext))
        return try await withCheckedThrowingContinuation { fetchContinuations.append($0) }
    }

    func fetchStatus(id: Int64) async throws -> CommentListItem.Status {
        throw FakeServiceError()
    }

    func setStatus(id: Int64, _ status: CommentListItem.Status) async throws -> CommentDetail {
        setStatusInvocations.append((id, status))
        return try await withCheckedThrowingContinuation { setStatusContinuations.append($0) }
    }

    func restore(id: Int64, from bin: CommentListItem.Status) async throws -> CommentDetail {
        throw FakeServiceError()
    }

    func resolveSetStatus(callIndex: Int, with detail: CommentDetail) {
        setStatusContinuations[callIndex].resume(returning: detail)
    }

    func failSetStatus(callIndex: Int, with error: Error) {
        setStatusContinuations[callIndex].resume(throwing: error)
    }

    func trash(id: Int64) async throws {
        throw FakeServiceError()
    }

    func delete(id: Int64) async throws {
        throw FakeServiceError()
    }

    func numberOfReplies(for id: Int64) async throws -> Int {
        numberOfRepliesInvocations.append(id)
        if let numberOfRepliesResult { return try numberOfRepliesResult.get() }
        return try await withCheckedThrowingContinuation { numberOfRepliesContinuations.append($0) }
    }

    func resolveNumberOfReplies(callIndex: Int, with count: Int) {
        numberOfRepliesContinuations[callIndex].resume(returning: count)
    }

    func resolveFetch(callIndex: Int, with detail: CommentDetail) {
        fetchContinuations[callIndex].resume(returning: detail)
    }
}
