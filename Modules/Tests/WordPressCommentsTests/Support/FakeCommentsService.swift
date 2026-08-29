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

    var fetchStatusResults: [Result<CommentListItem.Status, Error>] = []
    private(set) var fetchStatusInvocations: [Int64] = []

    var setStatusResult: Result<CommentDetail, Error>?
    private(set) var setStatusInvocations: [(id: Int64, status: CommentListItem.Status)] = []
    private(set) var restoreInvocations: [(id: Int64, from: CommentListItem.Status)] = []

    var trashError: Error?
    private(set) var trashInvocations: [Int64] = []

    var deleteError: Error?
    private(set) var deleteInvocations: [Int64] = []

    var numberOfRepliesResult: Result<Int, Error>?
    private(set) var numberOfRepliesInvocations: [Int64] = []

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

    func fetchStatus(id: Int64) async throws -> CommentListItem.Status {
        fetchStatusInvocations.append(id)
        guard !fetchStatusResults.isEmpty else { throw FakeServiceError() }
        return try fetchStatusResults.removeFirst().get()
    }

    func setStatus(id: Int64, _ status: CommentListItem.Status) async throws -> CommentDetail {
        setStatusInvocations.append((id, status))
        guard let setStatusResult else { throw FakeServiceError() }
        return try setStatusResult.get()
    }

    /// Shares `setStatusResult`: restore is the same update call on the wire.
    func restore(id: Int64, from bin: CommentListItem.Status) async throws -> CommentDetail {
        restoreInvocations.append((id, bin))
        guard let setStatusResult else { throw FakeServiceError() }
        return try setStatusResult.get()
    }

    func trash(id: Int64) async throws {
        trashInvocations.append(id)
        if let trashError { throw trashError }
    }

    func delete(id: Int64) async throws {
        deleteInvocations.append(id)
        if let deleteError { throw deleteError }
    }

    func numberOfReplies(for id: Int64) async throws -> Int {
        numberOfRepliesInvocations.append(id)
        guard let numberOfRepliesResult else { throw FakeServiceError() }
        return try numberOfRepliesResult.get()
    }
}

func makePage(items: [CommentListItem], hasNext: Bool) -> CommentsPage {
    CommentsPage(
        items: items,
        nextPage: hasNext ? CommentsPageToken(params: CommentListParams(page: 2)) : nil
    )
}
