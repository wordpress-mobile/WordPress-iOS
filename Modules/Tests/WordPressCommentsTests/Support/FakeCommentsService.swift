import Foundation
import WordPressAPI
@testable import WordPressComments

struct FakeServiceError: Error {}

@MainActor
final class FakeCommentsService: CommentsServiceProtocol {
    var queuedResults: [Result<CommentsPage, Error>] = []
    private(set) var requests: [(filter: CommentsListFilter, nextPage: CommentsPageToken?)] = []

    func listComments(filter: CommentsListFilter, nextPage: CommentsPageToken?) async throws -> CommentsPage {
        requests.append((filter, nextPage))
        guard !queuedResults.isEmpty else {
            throw FakeServiceError()
        }
        return try queuedResults.removeFirst().get()
    }
}

func makePage(items: [CommentListItem], hasNext: Bool) -> CommentsPage {
    CommentsPage(
        items: items,
        nextPage: hasNext ? CommentsPageToken(params: CommentListParams(page: 2)) : nil
    )
}
