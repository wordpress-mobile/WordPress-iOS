#if DEBUG
import Foundation

/// Canned service for SwiftUI previews. Every fetch resolves to
/// `CommentDetail.preview`; `fetchedStatus` and `numberOfReplies` shape the
/// detail screen's toolbar and trash confirmation.
@MainActor
final class PreviewCommentsService: CommentsServiceProtocol {
    private let fetchedStatus: CommentListItem.Status
    private let replyCount: Int

    init(fetchedStatus: CommentListItem.Status = .pending, numberOfReplies: Int = 0) {
        self.fetchedStatus = fetchedStatus
        self.replyCount = numberOfReplies
    }

    func listComments(filter: CommentsListFilter, nextPage: CommentsPageToken?) async throws -> CommentsPage {
        CommentsPage(items: [], nextPage: nil)
    }

    func fetchComment(id: Int64, allowsEditContext: Bool) async throws -> CommentDetail {
        .preview(id: id, status: fetchedStatus)
    }

    func fetchStatus(id: Int64) async throws -> CommentListItem.Status { fetchedStatus }
    func setStatus(id: Int64, _ status: CommentListItem.Status) async throws -> CommentDetail { .preview() }
    func restore(id: Int64, from bin: CommentListItem.Status) async throws -> CommentDetail { .preview() }
    func trash(id: Int64) async throws {}
    func delete(id: Int64) async throws {}
    func numberOfReplies(for id: Int64) async throws -> Int { replyCount }
}

struct PreviewCapabilities: CommentsCapabilitiesProtocol {
    func canModerateComments() async throws -> Bool { true }
}
#endif
