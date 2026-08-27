import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal
@testable import WordPressComments

/// Builds a composer over a fresh coordinator. `tracker` is shared by the
/// coordinator and the composer, as in production.
@MainActor
private func makeComposerVM(
    mode: CommentComposerViewModel.Mode,
    service: FakeCommentsService = FakeCommentsService(),
    store: FakeCommentDraftStore = FakeCommentDraftStore(),
    tracker: (any CommentsTracker)? = nil
) -> CommentComposerViewModel {
    CommentComposerViewModel(
        mode: mode,
        coordinator: CommentsModerationCoordinator(service: service, tracker: tracker),
        draftStore: store,
        tracker: tracker
    )
}

@MainActor
struct CommentComposerViewModelTests {

    // MARK: - Construction and gating

    @Test func replyModeRestoresDraftOnInit() {
        let store = FakeCommentDraftStore()
        store.preloadDraft("draft", commentID: 1)

        let vm = makeComposerVM(mode: .reply(parent: makeDetail(id: 1)), store: store)

        #expect(vm.text == "draft")
    }

    @Test func editModeSeedsRawContentAndIgnoresDrafts() {
        let store = FakeCommentDraftStore()
        store.preloadDraft("should not be used", commentID: 1)

        let vm = makeComposerVM(
            mode: .edit(comment: makeDetail(id: 1, editContext: true, content: "raw")),
            store: store
        )

        #expect(vm.text == "raw")
    }

    @Test func editModeFallsBackToEmptyWithoutRaw() {
        let vm = makeComposerVM(mode: .edit(comment: makeDetail(id: 1, editContext: false)))

        #expect(vm.text.isEmpty)
    }

    @Test func approveNoteShownOnlyForPendingReplyParent() {
        let pendingVM = makeComposerVM(mode: .reply(parent: makeDetail(status: .hold)))
        #expect(pendingVM.showsApproveNote)

        let approvedVM = makeComposerVM(mode: .reply(parent: makeDetail(status: .approved)))
        #expect(!approvedVM.showsApproveNote)

        let editVM = makeComposerVM(mode: .edit(comment: makeDetail(status: .hold, editContext: true)))
        #expect(!editVM.showsApproveNote)
    }

    @Test func canSendRequiresNonEmptyTrimmedText() {
        let vm = makeComposerVM(mode: .reply(parent: makeDetail()))

        vm.text = "  \n"
        #expect(!vm.canSend)

        vm.text = "hi"
        #expect(vm.canSend)
    }

    @Test func editCanSendRequiresChange() {
        let vm = makeComposerVM(mode: .edit(comment: makeDetail(editContext: true, content: "raw")))

        #expect(!vm.canSend) // text still equals the original raw content

        vm.text = "raw edited"
        #expect(vm.canSend)
    }

    // MARK: - Send: reply

    @Test func sendReplyApprovesOnlyAPendingParent() async {
        let pendingService = FakeCommentsService()
        pendingService.createReplyResult = .success(makeDetail(id: 99, status: .approved))
        pendingService.setStatusResult = .success(makeDetail(id: 1, status: .approved))
        let pendingVM = makeComposerVM(mode: .reply(parent: makeDetail(id: 1, status: .hold)), service: pendingService)
        pendingVM.text = "hi"
        _ = await pendingVM.send()
        #expect(pendingService.setStatusInvocations.map(\.status) == [.approved])

        let approvedService = FakeCommentsService()
        approvedService.createReplyResult = .success(makeDetail(id: 99, status: .approved))
        let approvedVM = makeComposerVM(
            mode: .reply(parent: makeDetail(id: 1, status: .approved)),
            service: approvedService
        )
        approvedVM.text = "hi"
        _ = await approvedVM.send()
        #expect(approvedService.setStatusInvocations.isEmpty)
    }

    @Test func sendReplySuccessDeletesDraftAndReturnsNotice() async {
        let service = FakeCommentsService()
        service.createReplyResult = .success(makeDetail(id: 99, status: .approved))
        let spy = SpyCommentsTracker()
        let store = FakeCommentDraftStore()
        store.preloadDraft("draft", commentID: 1)
        let vm = makeComposerVM(
            mode: .reply(parent: makeDetail(id: 1, status: .approved)),
            service: service,
            store: store,
            tracker: spy
        )
        vm.text = "hi"

        let outcome = await vm.send()

        #expect(outcome == .replied(notice: Strings.noticeReplySent))
        #expect(store.deleted == [1])
        // repliedTo is tracked by the coordinator, not the composer; the
        // composer only ever tracks editorOpened, and only in edit mode.
        #expect(!spy.trackedEvents.contains(.editorOpened(commentID: 1, postID: 10)))
    }

    @Test func sendReplyPendingStatusWordsNoticeAccordingly() async {
        let service = FakeCommentsService()
        service.createReplyResult = .success(makeDetail(id: 99, status: .hold))
        let vm = makeComposerVM(mode: .reply(parent: makeDetail(id: 1, status: .approved)), service: service)
        vm.text = "hi"

        let outcome = await vm.send()

        #expect(outcome == .replied(notice: Strings.noticeReplyPending))
    }

    @Test func sendReplyAlreadyPostedWordsNoticeAccordingly() async {
        let service = FakeCommentsService()
        service.createReplyResult = .failure(WpApiError.stub(code: .CommentDuplicate))
        let store = FakeCommentDraftStore()
        store.preloadDraft("draft", commentID: 1)
        let vm = makeComposerVM(
            mode: .reply(parent: makeDetail(id: 1, status: .approved)),
            service: service,
            store: store
        )
        vm.text = "hi"

        let outcome = await vm.send()

        #expect(outcome == .replied(notice: Strings.noticeReplyAlreadyPosted))
        #expect(store.deleted == [1])
    }

    @Test func sendReplyFailureShowsErrorAndKeepsDraftIntact() async {
        let service = FakeCommentsService()
        service.createReplyResult = .failure(FakeServiceError())
        let store = FakeCommentDraftStore()
        store.preloadDraft("draft", commentID: 1)
        let vm = makeComposerVM(
            mode: .reply(parent: makeDetail(id: 1, status: .approved)),
            service: service,
            store: store
        )
        vm.text = "hi"

        let outcome = await vm.send()

        #expect(outcome == nil)
        #expect(vm.errorMessage == Strings.composerErrorReplyFailed)
        #expect(!vm.isSending)
        #expect(store.deleted.isEmpty)
    }

    @Test func sendReplyClosedErrorShowsClosedMessage() async {
        let service = FakeCommentsService()
        service.createReplyResult = .failure(WpApiError.stub(code: .CommentClosed))
        let vm = makeComposerVM(mode: .reply(parent: makeDetail(id: 1, status: .approved)), service: service)
        vm.text = "hi"

        let outcome = await vm.send()

        #expect(outcome == nil)
        #expect(vm.errorMessage == Strings.composerErrorClosed)
    }

    // MARK: - Send: edit

    @Test func sendEditReturnsEditedOutcome() async {
        let service = FakeCommentsService()
        let comment = makeDetail(id: 1, editContext: true, content: "raw")
        service.updateContentResult = .success(makeEditedDetail(id: 1, contentHTML: "<p>new</p>", contentRaw: "new"))
        let vm = makeComposerVM(mode: .edit(comment: comment), service: service)
        vm.text = "new"

        let outcome = await vm.send()

        #expect(outcome == .edited)
    }

    @Test func sendEditFailureShowsEditError() async {
        let service = FakeCommentsService()
        service.updateContentResult = .failure(FakeServiceError())
        let comment = makeDetail(id: 1, editContext: true, content: "raw")
        let vm = makeComposerVM(mode: .edit(comment: comment), service: service)
        vm.text = "new"

        let outcome = await vm.send()

        #expect(outcome == nil)
        #expect(vm.errorMessage == Strings.composerErrorEditFailed)
    }

    // MARK: - Cancel flows

    @Test func replyIsDirtyOnlyWithNonBlankText() {
        let vm = makeComposerVM(mode: .reply(parent: makeDetail(id: 1)))
        #expect(!vm.isDirty)

        vm.text = "  \n"
        #expect(!vm.isDirty)

        vm.text = "hi"
        #expect(vm.isDirty)
    }

    @Test func editIsDirtyOnlyWhenTextDiffersFromOriginal() {
        let vm = makeComposerVM(mode: .edit(comment: makeDetail(id: 1, editContext: true, content: "raw")))
        #expect(!vm.isDirty)

        vm.text = "raw edited"
        #expect(vm.isDirty)
    }

    @Test func saveDraftPersists() {
        let store = FakeCommentDraftStore()
        let vm = makeComposerVM(mode: .reply(parent: makeDetail(id: 1)), store: store)
        vm.text = "draft text"

        vm.saveDraft()

        #expect(store.saved[1] == "draft text")
    }

    @Test func deleteDraftDeletes() {
        let store = FakeCommentDraftStore()
        let vm = makeComposerVM(mode: .reply(parent: makeDetail(id: 1)), store: store)

        vm.deleteDraft()

        #expect(store.deleted.contains(1))
    }

    @Test func deleteDraftIfBlankDeletesOnlyWhenTextIsBlank() {
        let store = FakeCommentDraftStore()
        store.preloadDraft("draft", commentID: 1)
        let vm = makeComposerVM(mode: .reply(parent: makeDetail(id: 1)), store: store)

        vm.deleteDraftIfBlank()
        #expect(store.deleted.isEmpty)

        vm.text = " \n"
        vm.deleteDraftIfBlank()
        #expect(store.deleted == [1])
    }

    // MARK: - Analytics

    @Test func editModeTracksEditorOpenedOnce() {
        let spy = SpyCommentsTracker()

        _ = makeComposerVM(
            mode: .edit(comment: makeDetail(id: 1, post: 10, editContext: true, content: "raw")),
            tracker: spy
        )

        #expect(spy.trackedEvents == [.editorOpened(commentID: 1, postID: 10)])
    }
}
