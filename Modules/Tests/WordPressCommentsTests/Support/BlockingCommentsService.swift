import Foundation
import WordPressAPI
@testable import WordPressComments

/// A service whose calls suspend until the test resolves them by index, so a
/// test can interleave an in-flight `loadMore` with a `refresh` deterministically.
@MainActor
final class BlockingCommentsService: CommentsServiceProtocol {
    private var continuations: [CheckedContinuation<CommentsPage, Error>] = []
    private(set) var callCount = 0

    func listComments(filter: CommentsListFilter, nextPage: CommentsPageToken?) async throws -> CommentsPage {
        callCount += 1
        return try await withCheckedThrowingContinuation { continuations.append($0) }
    }

    func resolve(callIndex: Int, with page: CommentsPage) {
        continuations[callIndex].resume(returning: page)
    }
}
