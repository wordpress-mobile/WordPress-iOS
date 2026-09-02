import Foundation
import WordPressAPI
import WordPressAPIInternal
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

    /// Fetches full comment detail. When `allowsEditContext` is true, tries
    /// edit context first (adds author email/IP) and falls back to view
    /// context on a 401/403 (stale cached capability after a demotion).
    func fetchComment(id: Int64, allowsEditContext: Bool) async throws -> CommentDetail

    /// Fetches only the comment's current status. Used for the same-status
    /// probe, where the caller only needs "where is this comment now" rather
    /// than the full comment payload.
    func fetchStatus(id: Int64) async throws -> CommentListItem.Status

    /// Writes `status` and returns the updated detail. Restoring from spam or
    /// trash goes through `restore(id:from:)` instead: core uses dedicated
    /// operations for that, not a plain status write.
    func setStatus(id: Int64, _ status: CommentListItem.Status) async throws -> CommentDetail

    /// Restores a comment from `bin` (`.spam` or `.trash`) via core's dedicated
    /// unspam/untrash operations, which reapply the saved pre-bin status and
    /// fire the matching hooks. Returns the updated detail.
    func restore(id: Int64, from bin: CommentListItem.Status) async throws -> CommentDetail

    /// Soft-deletes the comment (moves it to trash; recoverable).
    func trash(id: Int64) async throws

    /// Permanently deletes the comment.
    func delete(id: Int64) async throws

    /// Total number of replies to `id`, read from the list response's
    /// `X-WP-Total` header rather than the (unused) page of results.
    func numberOfReplies(for id: Int64) async throws -> Int
}

/// Errors raised by `CommentsService` that don't originate from wordpress-rs.
enum CommentsServiceError: Error {
    /// A sparse field the caller asked for was absent from the response.
    /// Should not happen: the server always returns requested fields.
    case missingField
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

    func fetchComment(id: Int64, allowsEditContext: Bool) async throws -> CommentDetail {
        if allowsEditContext {
            do {
                // `CommentRetrieveParams` isn't re-exported by wordpress-rs's
                // `WordPressAPI` module (only used internally), so its name
                // can't be spelled here; `.init()` resolves it from the
                // parameter type instead.
                let response = try await client.api.comments.retrieveWithEditContext(
                    commentId: id,
                    params: .init()
                )
                return CommentDetail(comment: response.data)
            } catch {
                let statusCode = (error as? WpApiError)?.httpStatusCode
                guard statusCode == 401 || statusCode == 403 else { throw error }
                // Fall through to the view-context retry below.
            }
        }
        let response = try await client.api.comments.retrieveWithViewContext(
            commentId: id,
            params: .init()
        )
        return CommentDetail(comment: response.data)
    }

    func fetchStatus(id: Int64) async throws -> CommentListItem.Status {
        let response = try await client.api.comments.filterRetrieveWithViewContext(
            commentId: id,
            params: .init(),
            fields: [.status]
        )
        guard let status = response.data.status else { throw CommentsServiceError.missingField }
        return CommentListItem.Status(status)
    }

    func setStatus(id: Int64, _ status: CommentListItem.Status) async throws -> CommentDetail {
        try await update(id: id, status: Self.updateStatus(for: status))
    }

    func restore(id: Int64, from bin: CommentListItem.Status) async throws -> CommentDetail {
        try await update(id: id, status: Self.restoreStatus(from: bin))
    }

    private func update(id: Int64, status: CommentStatus) async throws -> CommentDetail {
        let response = try await client.api.comments.update(
            commentId: id,
            params: CommentUpdateParams(status: status)
        )
        return CommentDetail(comment: response.data)
    }

    /// The update-body spelling of a status (the body accepts `approved` but
    /// spells pending as `hold`).
    static func updateStatus(for status: CommentListItem.Status) -> CommentStatus {
        switch status {
        case .approved: .approved
        case .pending: .hold
        case .spam: .spam
        case .trash: .trash
        case .other(let raw): .custom(raw)
        }
    }

    /// Core's dedicated restore operations: they reapply the saved
    /// pre-spam/pre-trash status (not a plain hold write) and fire the
    /// unspam_comment/untrash_comment hooks.
    /// TODO: replace with typed wordpress-rs values when upstreamed.
    static func restoreStatus(from bin: CommentListItem.Status) -> CommentStatus {
        bin == .spam ? .custom("unspam") : .custom("untrash")
    }

    func trash(id: Int64) async throws {
        _ = try await client.api.comments.trash(commentId: id, params: .init())
    }

    func delete(id: Int64) async throws {
        _ = try await client.api.comments.delete(commentId: id, params: .init())
    }

    func numberOfReplies(for id: Int64) async throws -> Int {
        let response = try await client.api.comments.listWithViewContext(
            params: CommentListParams(perPage: 1, parent: [.init(id)], status: .all)
        )
        return Int(response.headerMap.wpTotal() ?? 0)
    }
}

extension WpApiError {
    /// The HTTP status code carried by the error, when it has one.
    var httpStatusCode: UInt32? {
        switch self {
        case .WpError(_, _, let statusCode, _, _, _): return statusCode
        case .RequestExecutionFailed(let statusCode, _, _, _, _): return statusCode
        default: return nil
        }
    }

    /// The WP REST error code carried by the error, when it has one. Used to
    /// map the bounded moderation failures (`rest_comment_failed_edit`,
    /// `rest_already_trashed`) to their real outcomes.
    var wpErrorCode: WpErrorCode? {
        if case .WpError(let errorCode, _, _, _, _, _) = self { return errorCode }
        return nil
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
