import Combine
import Foundation
import WordPressShared

/// Drives the comment detail and moderation screen. Reads the moderation
/// capability from the shared resolver when already known (so the toolbar and
/// nav bar items render on the first frame), else awaits it once; runs the
/// authoritative detail/parent/reply-count fetches,
/// and enforces the ordering rules the design requires: no action lands before
/// the authoritative fetch, the toolbar is disabled while a mutation is in
/// flight, and an open screen still hears late status changes by subscribing to
/// coordinator events for its comment ID.
///
/// Moderation is pessimistic: the tapped action shows an in-place spinner, the
/// coordinator emits its change event only after the request succeeds, and a
/// failure posts an app-wide notice with the screen still on the true
/// pre-action state.
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

    /// The confirmation a trash action should present. `numberOfReplies` is
    /// unknown until the count fetch lands, so an unknown count falls back to a
    /// generic confirmation rather than silently trashing a thread.
    enum TrashConfirmation: Equatable {
        case none // 0 replies: no confirmation needed
        case generic // reply count unknown
        case withReplies
    }

    @Published private(set) var content: ContentState = .loading
    @Published private(set) var canModerate: Bool? // nil = resolving
    @Published private(set) var parentPreview: CommentListItem? // "In reply to" strip
    @Published private(set) var numberOfReplies: Int? // nil = unknown
    /// The action whose request is in flight, or nil. Drives the per-button
    /// spinner and gates the toolbar synchronously (the coordinator's
    /// `isMutating` only flips after the first suspension).
    @Published private(set) var pendingAction: CommentModerationAction?
    /// Set by a `.deleted` event (a confirmed delete), which turns the toolbar
    /// off and makes the view dismiss itself. Cleared by a successful
    /// authoritative fetch or a later status change proving the comment exists
    /// again.
    @Published private(set) var isDeleted = false

    let commentID: Int64

    /// The fetched detail once it lands, else the list seed, else nil
    /// (seedless: show placeholders). Derived so the status has one source.
    var header: Header? {
        if let detail = loadedDetail { return Header(detail: detail) }
        return seed.map(Header.init(seed:))
    }

    var loadedDetail: CommentDetail? {
        if case .loaded(let detail) = content { return detail }
        return nil
    }

    /// Toolbar renders when the user can moderate AND edit context stuck. Once
    /// the detail lands, a view-context fallback (no edit context) means the
    /// capability was stale; hide the toolbar for this screen.
    var showsToolbar: Bool {
        guard !isDeleted, canModerate == true else { return false }
        return loadedDetail?.hasEditContext ?? true
    }

    /// The toolbar's shape for the live header status (the screen's status
    /// source of truth).
    var toolbarModel: CommentModerationToolbarModel {
        .make(status: header?.status, showsToolbar: showsToolbar)
    }

    /// Enabled only on fetched truth and while no mutation is in flight. The
    /// local `pendingAction` is the synchronous double-tap guard; the
    /// coordinator's `isMutating` also covers a mutation started before this
    /// screen opened.
    var isToolbarEnabled: Bool {
        actionableDetail != nil && pendingAction == nil
    }

    var trashConfirmation: TrashConfirmation {
        switch numberOfReplies {
        case .none: .generic
        case .some(0): .none
        case .some: .withReplies
        }
    }

    /// The fetched detail when the user may act on it: the toolbar shows, the
    /// load has finished, and no mutation is in flight for this comment. The
    /// load gate matters because the reply count lands after the comment: a
    /// reply sent before it could be missed by the landed count and let the
    /// parent be trashed without a warning.
    private var actionableDetail: CommentDetail? {
        guard showsToolbar, !isLoading, !coordinator.isMutating(id: commentID) else { return nil }
        return loadedDetail
    }

    private let seed: CommentListItem?
    private let service: any CommentsServiceProtocol
    private let capabilities: CommentsCapabilityResolver
    private let coordinator: CommentsModerationCoordinator
    private let titleResolver: PostTitleResolver
    /// Fires `.detailViewed` once per screen, on the first successful fetch.
    private let tracker: (any CommentsTracker)?
    private let noticePresenter: (any NoticePresenting)?

    /// A load (capability + fetch) is currently running; guards re-entry.
    private var isLoading = false

    private var eventSubscription: AnyCancellable?

    init(
        commentID: Int64,
        seed: CommentListItem?,
        service: any CommentsServiceProtocol,
        capabilities: CommentsCapabilityResolver,
        coordinator: CommentsModerationCoordinator,
        titleResolver: PostTitleResolver,
        tracker: (any CommentsTracker)? = nil,
        noticePresenter: (any NoticePresenting)? = nil
    ) {
        self.commentID = commentID
        self.seed = seed
        self.service = service
        self.capabilities = capabilities
        canModerate = capabilities.canModerate
        self.coordinator = coordinator
        self.titleResolver = titleResolver
        self.tracker = tracker
        self.noticePresenter = noticePresenter
        // Deliberately not tied to the view's appearance: pushing a child screen
        // (e.g. the parent comment) hides this one, and a status change that
        // lands meanwhile must still correct the header/toolbar. Lives for the
        // VM's lifetime.
        eventSubscription = coordinator.events
            .filter { $0.commentID == commentID }
            .sink { [weak self] in self?.handle($0) }
    }

    func onAppear() async {
        guard loadedDetail == nil, !isLoading else { return }
        await load()
    }

    func retry() async {
        guard !isLoading else { return }
        content = .loading
        await load()
    }

    /// Runs a moderation action pessimistically: the tapped button shows a
    /// spinner while the request is in flight, and the UI changes only once the
    /// coordinator's post-success event has updated the loaded detail. Ignored
    /// unless the toolbar is enabled (authoritative truth landed and no
    /// mutation is in flight), so an action can never run before the fetch.
    func perform(_ action: CommentModerationAction) {
        guard isToolbarEnabled, let detail = loadedDetail else { return }
        pendingAction = action
        Task { [coordinator, noticePresenter, weak self] in
            do {
                try await coordinator.perform(action, on: detail)
            } catch {
                noticePresenter?.present(title: Strings.moderationFailed)
            }
            self?.pendingAction = nil
        }
    }

    // MARK: - Loading

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        if canModerate == nil {
            // A failed lookup degrades this screen to read-only (view-context
            // fetch, no author email or IP) without blocking it.
            canModerate = await capabilities.resolve() ?? false
        }
        await runFetch()
    }

    /// Runs the authoritative fetch. Waits for any in-flight mutation to settle
    /// first, so the fetch reads post-commit state. A mutation cannot start
    /// mid-fetch from this screen (the toolbar stays disabled until the fetch
    /// lands), and a success event arriving later corrects the status anyway.
    private func runFetch() async {
        guard let canModerate else { return }
        await coordinator.waitForPendingMutation(id: commentID)

        // The reply count only feeds the trash confirmation, so it runs
        // alongside the comment fetch (`.generic` covers the gap), is applied
        // last, and is skipped when the toolbar can never show.
        async let replies: Int? = canModerate ? (try? await service.numberOfReplies(for: commentID)) : nil
        guard let detail = try? await service.fetchComment(id: commentID, allowsEditContext: canModerate) else {
            _ = await replies
            content = .failed
            return
        }
        applyLoaded(detail)
        await loadParentPreview(for: detail)
        numberOfReplies = await replies
    }

    private func applyLoaded(_ detail: CommentDetail) {
        let isFirstFetch = loadedDetail == nil
        // A successful authoritative fetch proves the comment exists at a known
        // status, so clear any terminal (deleted) state (re-enabling the
        // toolbar). A genuinely deleted comment never reaches here: its fetch
        // fails into `.failed`.
        isDeleted = false
        content = .loaded(detail)
        titleResolver.resolve(ids: [detail.postID])
        // Fire once per screen, on the first successful fetch only.
        if isFirstFetch {
            tracker?.track(.detailViewed(commentID: commentID, postID: detail.postID))
        }
        // The list's status can be stale; broadcast the corrected status so any
        // loaded list tab reconciles without a full refetch.
        if let seed, seed.status != detail.status {
            coordinator.noteExternalStatus(id: commentID, to: detail.status)
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

    // MARK: - Coordinator events

    private func handle(_ event: CommentChangeEvent) {
        switch event {
        case .statusChanged(_, let to):
            // A status change proves the comment exists at a known status. Clear
            // any prior terminal state (e.g. a delete that later proved false)
            // so the toolbar can re-enable, then apply the status. The loaded
            // detail is the screen's status source of truth (header, pill, and
            // toolbar model all read it).
            isDeleted = false
            if var detail = loadedDetail {
                detail.status = to
                content = .loaded(detail)
            }
        case .deleted:
            // The comment is gone: a terminal state that turns the toolbar off
            // and dismisses the screen.
            isDeleted = true
        }
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
