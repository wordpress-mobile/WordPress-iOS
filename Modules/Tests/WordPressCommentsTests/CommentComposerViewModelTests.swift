import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal
@testable import WordPressComments

@MainActor
private func makeCoordinator(
    service: FakeCommentsService = FakeCommentsService(),
    tracker: (any CommentsTracker)? = nil
) -> CommentsModerationCoordinator {
    CommentsModerationCoordinator(service: service, tracker: tracker)
}

@MainActor
struct CommentComposerViewModelTests {

    // MARK: - Construction and gating

    @Test func replyModeRestoresDraftOnInit() {
        let store = FakeCommentDraftStore()
        store.preloadDraft("draft", commentID: 1)

        let vm = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(id: 1)),
            coordinator: makeCoordinator(),
            draftStore: store
        )

        #expect(vm.text == "draft")
    }

    @Test func approveNoteShownOnlyForPendingReplyParent() {
        let pendingVM = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(status: .hold)),
            coordinator: makeCoordinator(),
            draftStore: FakeCommentDraftStore()
        )
        #expect(pendingVM.showsApproveNote)

        let approvedVM = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(status: .approved)),
            coordinator: makeCoordinator(),
            draftStore: FakeCommentDraftStore()
        )
        #expect(!approvedVM.showsApproveNote)
    }

    @Test func canSendRequiresNonEmptyTrimmedText() {
        let vm = CommentComposerViewModel(
            mode: .reply(parent: makeDetail()),
            coordinator: makeCoordinator(),
            draftStore: FakeCommentDraftStore()
        )

        vm.text = "  \n"
        #expect(!vm.canSend)

        vm.text = "hi"
        #expect(vm.canSend)
    }

    // MARK: - Send: reply

    @Test func sendReplyPassesApproveParentForPendingParent() async {
        let pendingService = FakeCommentsService()
        pendingService.createReplyResult = .success(makeDetail(id: 99, status: .approved))
        pendingService.setStatusResult = .success(makeDetail(id: 1, status: .approved))
        let pendingVM = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(id: 1, status: .hold)),
            coordinator: makeCoordinator(service: pendingService),
            draftStore: FakeCommentDraftStore()
        )
        pendingVM.text = "hi"
        _ = await pendingVM.send()
        #expect(pendingService.setStatusInvocations.map(\.status) == [.approved])

        let approvedService = FakeCommentsService()
        approvedService.createReplyResult = .success(makeDetail(id: 99, status: .approved))
        let approvedVM = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(id: 1, status: .approved)),
            coordinator: makeCoordinator(service: approvedService),
            draftStore: FakeCommentDraftStore()
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
        let vm = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(id: 1, status: .approved)),
            coordinator: makeCoordinator(service: service, tracker: spy),
            draftStore: store,
            tracker: spy
        )
        vm.text = "hi"

        let outcome = await vm.send()

        #expect(outcome == .replied(notice: Strings.noticeReplySent))
        #expect(store.deleted == [1])
    }

    @Test func sendReplyPendingStatusWordsNoticeAccordingly() async {
        let service = FakeCommentsService()
        service.createReplyResult = .success(makeDetail(id: 99, status: .hold))
        let vm = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(id: 1, status: .approved)),
            coordinator: makeCoordinator(service: service),
            draftStore: FakeCommentDraftStore()
        )
        vm.text = "hi"

        let outcome = await vm.send()

        #expect(outcome == .replied(notice: Strings.noticeReplyPending))
    }

    @Test func sendReplyAlreadyPostedWordsNoticeAccordingly() async {
        let service = FakeCommentsService()
        service.createReplyResult = .failure(WpApiError.stub(code: .CommentDuplicate))
        let store = FakeCommentDraftStore()
        store.preloadDraft("draft", commentID: 1)
        let vm = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(id: 1, status: .approved)),
            coordinator: makeCoordinator(service: service),
            draftStore: store
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
        let vm = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(id: 1, status: .approved)),
            coordinator: makeCoordinator(service: service),
            draftStore: store
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
        let vm = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(id: 1, status: .approved)),
            coordinator: makeCoordinator(service: service),
            draftStore: FakeCommentDraftStore()
        )
        vm.text = "hi"

        let outcome = await vm.send()

        #expect(outcome == nil)
        #expect(vm.errorMessage == Strings.composerErrorClosed)
    }

    // MARK: - Cancel flows

    @Test func replyIsDirtyOnlyWithNonBlankText() {
        let vm = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(id: 1)),
            coordinator: makeCoordinator(),
            draftStore: FakeCommentDraftStore()
        )
        #expect(!vm.isDirty)

        vm.text = "  \n"
        #expect(!vm.isDirty)

        vm.text = "hi"
        #expect(vm.isDirty)
    }

    @Test func saveDraftPersists() {
        let store = FakeCommentDraftStore()
        let vm = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(id: 1)),
            coordinator: makeCoordinator(),
            draftStore: store
        )
        vm.text = "draft text"

        vm.saveDraft()

        #expect(store.saved[1] == "draft text")
    }

    @Test func deleteDraftDeletes() {
        let store = FakeCommentDraftStore()
        let vm = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(id: 1)),
            coordinator: makeCoordinator(),
            draftStore: store
        )

        vm.deleteDraft()

        #expect(store.deleted.contains(1))
    }

    @Test func deleteDraftIfBlankDeletesOnlyWhenTextIsBlank() {
        let store = FakeCommentDraftStore()
        store.preloadDraft("draft", commentID: 1)
        let vm = CommentComposerViewModel(
            mode: .reply(parent: makeDetail(id: 1)),
            coordinator: makeCoordinator(),
            draftStore: store
        )

        vm.deleteDraftIfBlank()
        #expect(store.deleted.isEmpty)

        vm.text = " \n"
        vm.deleteDraftIfBlank()
        #expect(store.deleted == [1])
    }
}
