import Foundation
import WordPressAPIInternal
import WordPressShared

/// Drives the reply/edit composer sheet. Every mutation delegates to
/// `CommentsModerationCoordinator`. `Identifiable` (by object identity) so the
/// detail screen can present it with `.sheet(item:)`.
@MainActor
final class CommentComposerViewModel: ObservableObject, Identifiable {
    enum Mode: Equatable {
        case reply(parent: CommentDetail)
        case edit(comment: CommentDetail)

        /// The comment whose draft this composer owns. Only replies keep
        /// drafts (legacy parity); edit mode never touches the store.
        var draftCommentID: Int64? {
            switch self {
            case .reply(let parent): parent.id
            case .edit: nil
            }
        }

        /// The text the composer opens with: the original content for an
        /// edit, empty for a reply (the caller layers a restored draft over it).
        var originalText: String {
            switch self {
            case .reply: ""
            case .edit(let comment): comment.contentRaw ?? ""
            }
        }

        var failureMessage: String {
            switch self {
            case .reply: Strings.composerErrorReplyFailed
            case .edit: Strings.composerErrorEditFailed
            }
        }
    }

    /// What the detail screen shows after the sheet dismisses.
    enum Outcome: Equatable {
        case replied(notice: String)
        case edited
    }

    @Published var text: String
    @Published private(set) var isSending = false
    @Published private(set) var errorMessage: String?

    let mode: Mode
    /// Reply mode only: the parent's author and one-line snippet, derived
    /// once (the sheet re-renders on every keystroke).
    let parentPreview: CommentListItem?

    var title: String {
        switch mode {
        case .reply: Strings.composerReplyTitle
        case .edit: Strings.composerEditTitle
        }
    }

    var sendButtonTitle: String {
        switch mode {
        case .reply: Strings.composerSend
        case .edit: Strings.composerSave
        }
    }

    var canSend: Bool {
        isDirty && !trimmedText.isEmpty
    }

    /// Reply mode only: sending will also approve the pending parent.
    var showsApproveNote: Bool {
        guard case .reply(let parent) = mode else { return false }
        return parent.status == .pending
    }

    /// Whether cancelling should ask before discarding: a reply with any
    /// non-blank text, or an edit that differs from the original.
    var isDirty: Bool {
        trimmedText != mode.originalText
    }

    private var trimmedText: String {
        text.trim()
    }

    private let coordinator: CommentsModerationCoordinator
    private let draftStore: any CommentDraftStoring
    private let tracker: (any CommentsTracker)?

    init(
        mode: Mode,
        coordinator: CommentsModerationCoordinator,
        draftStore: any CommentDraftStoring,
        tracker: (any CommentsTracker)? = nil
    ) {
        self.mode = mode
        self.coordinator = coordinator
        self.draftStore = draftStore
        self.tracker = tracker
        switch mode {
        case .reply(let parent):
            parentPreview = CommentListItem(detail: parent)
            text = draftStore.loadDraft(commentID: parent.id) ?? ""
        case .edit(let comment):
            parentPreview = nil
            text = mode.originalText
            // Matches legacy, which fires its edit-entry event when the
            // editor opens. Reply mode has no equivalent: the coordinator
            // tracks `.repliedTo` once the send succeeds.
            tracker?.track(.editorOpened(commentID: comment.id, postID: comment.postID))
        }
    }

    func send() async -> Outcome? {
        guard canSend, !isSending else { return nil }
        errorMessage = nil
        isSending = true
        defer { isSending = false }

        do {
            switch mode {
            case .reply(let parent):
                let outcome = try await coordinator.reply(to: parent, content: trimmedText)
                draftStore.deleteDraft(commentID: parent.id)
                return .replied(notice: notice(for: outcome))
            case .edit(let comment):
                _ = try await coordinator.editContent(on: comment, newContent: trimmedText)
                return .edited
            }
        } catch {
            errorMessage = errorText(for: error)
            return nil
        }
    }

    /// Reply mode only: keeps the current text for the next time the composer
    /// opens on this parent.
    func saveDraft() {
        guard let id = mode.draftCommentID else { return }
        draftStore.saveDraft(text, commentID: id)
    }

    func deleteDraft() {
        guard let id = mode.draftCommentID else { return }
        draftStore.deleteDraft(commentID: id)
    }

    /// Runs when the sheet closes. The blank exits (Cancel, swipe-down) skip
    /// the draft prompt, so a restored draft the user cleared is dropped here
    /// instead of coming back on the next open.
    func deleteDraftIfBlank() {
        guard let id = mode.draftCommentID, trimmedText.isEmpty else { return }
        draftStore.deleteDraft(commentID: id)
    }

    /// Words the post-send notice: a duplicate confirms an earlier send
    /// already landed, a pending status means the reply itself needs
    /// moderation, otherwise it posted straight away.
    private func notice(for outcome: ReplyOutcome) -> String {
        if outcome.alreadyPosted {
            return Strings.noticeReplyAlreadyPosted
        }
        if outcome.replyStatus == .pending {
            return Strings.noticeReplyPending
        }
        return Strings.noticeReplySent
    }

    /// Only comment_closed gets its own wording; every other failure (a
    /// duplicate never reaches here, the reply chain absorbs it) shows the
    /// mode's generic message.
    private func errorText(for error: Error) -> String {
        if (error as? WpApiError)?.wpErrorCode == .CommentClosed {
            return Strings.composerErrorClosed
        }
        return mode.failureMessage
    }
}
