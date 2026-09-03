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
    @Published var composer: CommentComposerViewModel? // non-nil = the composer sheet is presented
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

    /// Whether the Reply button renders. Reads the same seed-or-fetched status
    /// the toolbar does, so the button appears as soon as the capability
    /// resolves instead of after the whole load; `canReply` enables it.
    var showsReply: Bool {
        switch toolbarModel {
        case .approved, .pending: true
        case .inBin, .hidden: false
        }
    }

    /// Reply is reachable only for an active (approved/pending) comment, and
    /// only behind the moderation toolbar gate: the reply chain assumes a
    /// moderator (core auto-approves the reply; a pending parent is approved
    /// alongside it). Non-moderator reply is a follow-up that needs its own
    /// capability check and a chain that doesn't assume auto-approval.
    var canReply: Bool {
        showsReply && isToolbarEnabled
    }

    /// Whether the Edit menu item renders: the toolbar's seed-or-fetched gate
    /// (moderator, modeled status), so it appears with the toolbar rather than
    /// after the whole load; `canEdit` enables it.
    var showsEdit: Bool {
        toolbarModel != .hidden
    }

    /// The permalink to share, or nil. Only a publicly visible (approved)
    /// comment is shareable. Sharing needs no authoritative truth, so the
    /// seed's link serves until the fetch lands.
    var shareLink: URL? {
        guard header?.status == .approved else { return nil }
        return loadedDetail?.link ?? seed?.link
    }

    /// Edit context (and thus `contentRaw`) is already required by
    /// `showsToolbar`; the modeled-status restriction comes from `showsEdit`.
    var canEdit: Bool {
        showsEdit && isToolbarEnabled
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

    /// Presents the composer in reply mode. A no-op unless `canReply` (which
    /// already covers "no mutation in flight" via `isToolbarEnabled`).
    func replyTapped() {
        guard canReply, let detail = loadedDetail else { return }
        presentComposer(.reply(parent: detail))
    }

    /// Presents the composer in edit mode. Mirrors `replyTapped()`.
    func editTapped() {
        guard canEdit, let detail = loadedDetail else { return }
        presentComposer(.edit(comment: detail))
    }

    private func presentComposer(_ mode: CommentComposerViewModel.Mode) {
        guard composer == nil else { return }
        composer = CommentComposerViewModel(
            mode: mode,
            coordinator: coordinator,
            draftStore: draftStore,
            tracker: tracker
        )
    }

    /// Dismisses the composer sheet. A successful reply also posts its
    /// notice; a cancel (nil) or a successful edit needs none (the edited
    /// content updates in place via the coordinator's `contentChanged` event).
    func composerClosed(_ outcome: CommentComposerViewModel.Outcome?) {
        composer = nil
        if case .replied(let replyNotice) = outcome {
            noticePresenter?.present(title: replyNotice)
        }
    }

    private let seed: CommentListItem?
    private let service: any CommentsServiceProtocol
    private let capabilities: CommentsCapabilityResolver
    private let coordinator: CommentsModerationCoordinator
    private let draftStore: any CommentDraftStoring
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
        draftStore: any CommentDraftStoring,
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
        self.draftStore = draftStore
        self.titleResolver = titleResolver
        self.tracker = tracker
        self.noticePresenter = noticePresenter
        // Deliberately not tied to the view's appearance: pushing a child screen
        // (e.g. the parent comment) hides this one, and a status change that
        // lands meanwhile must still correct the header/toolbar. Lives for the
        // VM's lifetime.
        eventSubscription = coordinator.events.sink { [weak self] in self?.handle($0) }
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

    /// Routes every coordinator event: this comment's own events drive the
    /// screen; the parent's content edits (made on the parent's own detail
    /// screen) refresh the "In reply to" strip in place instead of showing a
    /// stale snippet until the next full fetch. Everything else is ignored.
    private func handle(_ event: CommentChangeEvent) {
        if event.commentID == parentPreview?.id {
            if case .contentChanged(_, let contentHTML, _) = event {
                parentPreview?.snippet = CommentListItem.snippet(fromHTML: contentHTML)
            }
            return
        }
        guard event.commentID == commentID else { return }
        switch event {
        case .statusChanged(_, let to):
            // A status change proves the comment exists at a known status. Clear
            // any prior terminal state (e.g. a delete that later proved false)
            // so the toolbar can re-enable, then apply the status. The loaded
            // detail is the screen's status source of truth (header, pill,
            // toolbar model, and Reply/Edit gating all read it).
            isDeleted = false
            if var detail = loadedDetail {
                detail.status = to
                content = .loaded(detail)
            }
        case .deleted:
            // The comment is gone: a terminal state that turns the toolbar off
            // and dismisses the screen.
            isDeleted = true
        case .contentChanged(_, let contentHTML, let contentRaw):
            if var detail = loadedDetail {
                detail.contentHTML = contentHTML
                detail.contentRaw = contentRaw
                content = .loaded(detail)
            }
        case .replyCreated:
            // The reply is a different comment; this screen's own status is
            // corrected by the approve step's statusChanged event when
            // relevant. Not a pure no-op, though: the cached reply count feeds
            // `trashConfirmation`, so it must be bumped when known, or a parent
            // that just gained its first reply could be trashed with no
            // confirmation.
            if let count = numberOfReplies {
                numberOfReplies = count + 1
            }
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
