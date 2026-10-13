import Foundation
import WordPressAPIInternal
import WordPressShared

/// Drives the reply composer sheet. Every mutation delegates to
/// `CommentsModerationCoordinator`.
@MainActor
final class CommentComposerViewModel: ObservableObject {
    enum Mode: Equatable {
        case reply(parent: CommentDetail)
    }

    /// What the detail screen shows after the sheet dismisses.
    enum Outcome: Equatable {
        case replied(notice: String)
    }

    @Published var text: String
    @Published private(set) var isSending = false
    @Published private(set) var errorMessage: String?

    let mode: Mode
    /// The parent's author and one-line snippet, derived once (the sheet
    /// re-renders on every keystroke).
    let parentPreview: CommentListItem

    var title: String {
        switch mode {
        case .reply: Strings.composerReplyTitle
        }
    }

    var sendButtonTitle: String {
        switch mode {
        case .reply: Strings.composerSend
        }
    }

    var canSend: Bool {
        guard !trimmedText.isEmpty else { return false }
        switch mode {
        case .reply: return true
        }
    }

    /// Reply mode only: sending will also approve the pending parent.
    var showsApproveNote: Bool {
        guard case .reply(let parent) = mode else { return false }
        return parent.status == .pending
    }

    /// Whether cancelling should ask before discarding: a reply with any
    /// non-blank text.
    var isDirty: Bool {
        switch mode {
        case .reply: !trimmedText.isEmpty
        }
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
        }
    }

    func send() async -> Outcome? {
        guard canSend, !isSending else { return nil }
        errorMessage = nil
        isSending = true
        defer { isSending = false }

        let content = trimmedText
        switch mode {
        case .reply(let parent):
            do {
                let outcome = try await coordinator.reply(to: parent, content: content)
                draftStore.deleteDraft(commentID: parent.id)
                return .replied(notice: notice(for: outcome))
            } catch {
                errorMessage = errorText(for: error)
                return nil
            }
        }
    }

    /// Keeps the current text for the next time the composer opens on this
    /// parent.
    func saveDraft() {
        guard case .reply(let parent) = mode else { return }
        draftStore.saveDraft(text, commentID: parent.id)
    }

    func deleteDraft() {
        guard case .reply(let parent) = mode else { return }
        draftStore.deleteDraft(commentID: parent.id)
    }

    /// Runs when the sheet closes. The blank exits (Cancel, swipe-down) skip
    /// the draft prompt, so a restored draft the user cleared is dropped here
    /// instead of coming back on the next open.
    func deleteDraftIfBlank() {
        guard case .reply(let parent) = mode, trimmedText.isEmpty else { return }
        draftStore.deleteDraft(commentID: parent.id)
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
    /// generic reply-failed message.
    private func errorText(for error: Error) -> String {
        if (error as? WpApiError)?.wpErrorCode == .CommentClosed {
            return Strings.composerErrorClosed
        }
        return Strings.composerErrorReplyFailed
    }
}
