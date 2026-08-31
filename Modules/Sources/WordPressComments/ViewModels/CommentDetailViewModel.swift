import Foundation
import WordPressShared

/// Drives the read-only comment detail screen. Resolves the capability once,
/// fetches the authoritative detail and optional parent preview, and keeps the
/// seeded header visible while the request is in flight.
@MainActor
final class CommentDetailViewModel: ObservableObject {
    enum ContentState: Equatable {
        case loading
        case loaded(CommentDetail)
        case failed
    }

    /// Paintable from either the list seed or the fetched detail.
    struct Header: Equatable {
        let authorName: String
        let avatarURL: URL?
        let postID: Int64
        let date: Date
        let status: CommentListItem.Status
    }

    @Published private(set) var header: Header? // nil = seedless, show placeholders
    @Published private(set) var content: ContentState = .loading
    @Published private(set) var canModerate: Bool? // nil = resolving
    @Published private(set) var parentPreview: CommentListItem? // "In reply to" strip

    let commentID: Int64

    private let service: any CommentsServiceProtocol
    private let capabilities: any CommentsCapabilitiesProtocol
    private let titleResolver: PostTitleResolver
    /// Fires `.detailViewed` once per screen, on the first successful fetch.
    private let tracker: (any CommentsTracker)?

    /// The authoritative fetch has landed successfully at least once.
    private var hasFetched = false
    /// A load (capability + fetch) is currently running; guards re-entry.
    private var isLoading = false

    init(
        commentID: Int64,
        seed: CommentListItem?,
        service: any CommentsServiceProtocol,
        capabilities: any CommentsCapabilitiesProtocol,
        titleResolver: PostTitleResolver,
        tracker: (any CommentsTracker)? = nil
    ) {
        self.commentID = commentID
        self.service = service
        self.capabilities = capabilities
        self.titleResolver = titleResolver
        self.tracker = tracker
        if let seed {
            header = Header(seed: seed)
        }
    }

    func onAppear() async {
        guard !hasFetched, !isLoading else { return }
        await load()
    }

    func retry() async {
        guard !isLoading else { return }
        content = .loading
        await load()
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        if canModerate == nil {
            canModerate = await capabilities.canModerateComments()
        }
        await runFetch()
    }

    private func runFetch() async {
        guard let canModerate else { return }
        guard
            let detail = try? await service.fetchComment(
                id: commentID,
                allowsEditContext: canModerate
            )
        else {
            content = .failed
            return
        }
        applyLoaded(detail)
        await loadParentPreview(for: detail)
    }

    private func applyLoaded(_ detail: CommentDetail) {
        let isFirstFetch = !hasFetched
        hasFetched = true
        content = .loaded(detail)
        header = Header(detail: detail)
        titleResolver.resolve(ids: [detail.postID])
        if isFirstFetch {
            tracker?.track(.detailViewed(commentID: commentID, postID: detail.postID))
        }
    }

    private func loadParentPreview(for detail: CommentDetail) async {
        guard let parentID = detail.parentID else {
            parentPreview = nil
            return
        }
        // The parent is always read with view context; the strip never needs
        // the author email/IP that edit context would add.
        guard let parent = try? await service.fetchComment(id: parentID, allowsEditContext: false) else {
            parentPreview = nil // failure hides the strip
            return
        }
        parentPreview = CommentListItem(detail: parent)
    }
}

private extension CommentDetailViewModel.Header {
    init(seed: CommentListItem) {
        self.init(
            authorName: seed.authorName,
            avatarURL: seed.avatarURL,
            postID: seed.postID,
            date: seed.date,
            status: seed.status
        )
    }

    init(detail: CommentDetail) {
        self.init(
            authorName: detail.authorName,
            avatarURL: detail.avatarURL,
            postID: detail.postID,
            date: detail.date,
            status: detail.status
        )
    }
}
