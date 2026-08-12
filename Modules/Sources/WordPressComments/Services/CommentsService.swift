import Foundation
import WordPressAPI
import WordPressCore

/// Opaque next-page cursor. Wraps the wordpress-rs `nextPageParams` (parsed
/// from the response's `Link: rel="next"` header) so uniffi pagination types
/// never leak past the service.
///
/// The underlying pagination is offset-based (`page=N`): when the result set
/// changes between requests the window shifts, so a page can re-serve an item
/// (deduplicated by the view model) or skip one (inherent to offset paging;
/// pull-to-refresh is the recovery).
struct CommentsPageToken: Sendable {
    let params: CommentListParams
}

struct CommentsPage: Sendable {
    let items: [CommentListItem]
    let nextPage: CommentsPageToken?
}

protocol CommentsServiceProtocol: Sendable {
    /// Fetches one page. Pass `nil` for the first page; pass the previous
    /// page's token for the next one. A `nil` token in the result means the
    /// end of the list. Post titles are not part of this call; they resolve
    /// asynchronously through `PostTitleResolver`.
    func listComments(filter: CommentsListFilter, nextPage: CommentsPageToken?) async throws -> CommentsPage
}

final class CommentsService: CommentsServiceProtocol {
    private let client: WordPressClient

    init(client: WordPressClient) {
        self.client = client
    }

    func listComments(filter: CommentsListFilter, nextPage: CommentsPageToken?) async throws -> CommentsPage {
        let params = nextPage?.params ?? filter.firstPageParams
        let response = try await client.api.comments.listWithViewContext(params: params)
        return CommentsPage(
            items: response.data.map(CommentListItem.init),
            nextPage: response.nextPageParams.map(CommentsPageToken.init)
        )
    }
}

extension CommentsListFilter {
    static let pageSize: UInt32 = 20

    var firstPageParams: CommentListParams {
        CommentListParams(
            perPage: Self.pageSize,
            order: .desc,
            orderby: .dateGmt,
            status: queryStatus
        )
    }
}
