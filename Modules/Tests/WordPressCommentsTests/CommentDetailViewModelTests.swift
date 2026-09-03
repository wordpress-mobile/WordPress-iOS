import Foundation
import Testing
import WordPressAPI
@testable import WordPressComments

@MainActor
struct CommentDetailViewModelTests {
    @Test func seededHeaderPaintsBeforeFetch() {
        let seed = makeItem(id: 1, authorName: "Ada", post: 42, status: .hold)
        let vm = makeVM(seed: seed, service: FakeCommentsService())

        let header = vm.header
        #expect(header?.authorName == "Ada")
        #expect(header?.postID == 42)
        #expect(header?.status == .pending)
    }

    @Test func seedlessHeaderIsNilUntilFetch() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, status: .approved))
        let vm = makeVM(seed: nil, service: service)

        #expect(vm.header == nil)

        await vm.onAppear()
        #expect(vm.header?.status == .approved)
    }

    @Test func capabilityTrueFetchesEditContext() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, editContext: true))
        let vm = makeVM(service: service)

        await vm.onAppear()

        #expect(service.fetchCommentInvocations.last?.allowsEditContext == true)
    }

    @Test func capabilityFalseFetchesViewContextAndHidesToolbar() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1))
        let capabilities = FakeCommentsCapabilities()
        capabilities.canModerate = false
        let vm = makeVM(service: service, capabilities: capabilities)

        await vm.onAppear()

        #expect(service.fetchCommentInvocations.last?.allowsEditContext == false)
        #expect(vm.showsToolbar == false)
    }

    @Test func editContextFallbackHidesToolbar() async {
        // Capability says canModerate, but the fetch fell back to view context
        // (hasEditContext == false): a stale, demoted capability. The toolbar
        // must hide for this screen.
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, editContext: false))
        let vm = makeVM(service: service)

        await vm.onAppear()

        #expect(service.fetchCommentInvocations.last?.allowsEditContext == true)
        #expect(vm.showsToolbar == false)
    }

    @Test func toolbarDisabledUntilFetchCompletes() async {
        let service = BlockingCommentsService()
        let vm = makeVM(service: service)

        async let appear: Void = vm.onAppear()
        await waitUntil { !service.fetchCommentInvocations.isEmpty }

        // Capability resolved, fetch still in flight: toolbar renders but is
        // disabled until authoritative truth lands.
        #expect(vm.showsToolbar == true)
        #expect(vm.isToolbarEnabled == false)

        service.resolveFetch(callIndex: 0, with: makeDetail(id: 1, editContext: true))
        await appear

        #expect(vm.isToolbarEnabled == true)
    }

    // MARK: - Pessimistic moderation

    @Test func performKeepsPreActionStatusWhileRequestInFlight() async {
        let noticePresenter = FakeNoticePresenter()
        let coordinatorService = BlockingCommentsService()
        let coordinator = CommentsModerationCoordinator(service: coordinatorService)
        let vm = await makeLoadedVM(status: .hold, coordinator: coordinator, noticePresenter: noticePresenter)
        #expect(vm.header?.status == .pending)
        #expect(vm.isToolbarEnabled)

        vm.perform(.approve)
        // The spinner state is set synchronously; the toolbar disables at once.
        #expect(vm.pendingAction == .approve)
        #expect(vm.isToolbarEnabled == false)

        await waitUntil { !coordinatorService.setStatusInvocations.isEmpty }
        // Still blocked on the request: the status stays pre-action (no
        // optimistic flip) and nothing is emitted yet.
        #expect(vm.header?.status == .pending)
        #expect(noticePresenter.presented.isEmpty)

        coordinatorService.resolveSetStatus(callIndex: 0, with: makeDetail(id: 1, status: .approved, editContext: true))
        await waitUntil { vm.pendingAction == nil }

        // Only after the request succeeds does the status flip and the toolbar
        // re-enable.
        #expect(vm.header?.status == .approved)
        #expect(vm.isToolbarEnabled)
    }

    @Test func performSuccessUpdatesStatusAndClearsPending() async {
        let noticePresenter = FakeNoticePresenter()
        let coordinatorService = FakeCommentsService()
        coordinatorService.setStatusResult = .success(makeDetail(id: 1, status: .approved))
        let coordinator = CommentsModerationCoordinator(service: coordinatorService)
        let vm = await makeLoadedVM(status: .hold, coordinator: coordinator, noticePresenter: noticePresenter)
        vm.perform(.approve)
        await waitUntil { vm.pendingAction == nil }

        #expect(vm.header?.status == .approved)
        #expect(vm.pendingAction == nil)
        #expect(noticePresenter.presented.isEmpty)
        #expect(vm.isToolbarEnabled)
    }

    @Test func performFailureKeepsStatusAndShowsNotice() async {
        let noticePresenter = FakeNoticePresenter()
        let coordinatorService = FakeCommentsService()
        coordinatorService.setStatusResult = .failure(FakeServiceError())
        let coordinator = CommentsModerationCoordinator(service: coordinatorService)
        let vm = await makeLoadedVM(status: .hold, coordinator: coordinator, noticePresenter: noticePresenter)
        vm.perform(.approve)
        await waitUntil { vm.pendingAction == nil }

        // The action genuinely failed: the screen stays on the pre-action
        // status, posts the app-wide notice, and re-enables the toolbar.
        #expect(vm.header?.status == .pending)
        #expect(noticePresenter.presented == ["That action couldn't be completed. Please try again."])
        #expect(vm.pendingAction == nil)
        #expect(vm.isToolbarEnabled)
    }

    @Test func secondPerformAfterFailurePresentsSecondNotice() async {
        let noticePresenter = FakeNoticePresenter()
        let coordinatorService = FakeCommentsService()
        coordinatorService.setStatusResult = .failure(FakeServiceError())
        let coordinator = CommentsModerationCoordinator(service: coordinatorService)
        let vm = await makeLoadedVM(status: .hold, coordinator: coordinator, noticePresenter: noticePresenter)
        vm.perform(.approve)
        await waitUntil { vm.pendingAction == nil }
        #expect(noticePresenter.presented.count == 1)

        vm.perform(.approve)
        await waitUntil { vm.pendingAction == nil }
        #expect(
            noticePresenter.presented == [
                "That action couldn't be completed. Please try again.",
                "That action couldn't be completed. Please try again."
            ]
        )
    }

    @Test func actionBeforeFetchIsIgnored() async {
        let service = BlockingCommentsService()
        let coordinatorService = FakeCommentsService()
        let coordinator = CommentsModerationCoordinator(service: coordinatorService)
        let vm = makeVM(service: service, coordinator: coordinator)

        async let appear: Void = vm.onAppear()
        await waitUntil { !service.fetchCommentInvocations.isEmpty }

        // Fetch not yet landed: an action must be ignored (no mutation, no
        // pending state).
        vm.perform(.spam)
        #expect(vm.pendingAction == nil)
        #expect(coordinatorService.setStatusInvocations.isEmpty)

        service.resolveFetch(callIndex: 0, with: makeDetail(id: 1, editContext: true))
        await appear
    }

    @Test func toolbarDisabledWhileMutationInFlight() async {
        let coordinatorService = BlockingCommentsService()
        let coordinator = CommentsModerationCoordinator(service: coordinatorService)
        let vm = await makeLoadedVM(status: .approved, coordinator: coordinator)
        #expect(vm.isToolbarEnabled == true)

        vm.perform(.spam)
        #expect(vm.pendingAction == .spam)
        #expect(vm.isToolbarEnabled == false)

        await waitUntil { !coordinatorService.setStatusInvocations.isEmpty }
        #expect(vm.isToolbarEnabled == false)
        coordinatorService.resolveSetStatus(callIndex: 0, with: makeDetail(id: 1, status: .spam, editContext: true))
        await waitUntil { vm.pendingAction == nil }

        #expect(vm.isToolbarEnabled == true)
    }

    @Test func seedStatusMismatchEmitsEvent() async {
        let seed = makeItem(id: 1, status: .hold) // list showed pending
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, status: .approved)) // server says approved
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let recorder = EventRecorder(coordinator)
        let vm = makeVM(seed: seed, service: service, coordinator: coordinator)

        await vm.onAppear()

        #expect(recorder.events == [.statusChanged(id: 1, to: .approved)])
        #expect(vm.header?.status == .approved)
    }

    @Test func reEntryFetchAwaitsPendingMutation() async {
        let coordinatorService = BlockingCommentsService()
        let coordinator = CommentsModerationCoordinator(service: coordinatorService)
        // A mutation is already in flight for this comment (started elsewhere).
        let mutation = Task { try? await coordinator.perform(.approve, on: makeDetail(id: 1, status: .hold)) }
        await waitUntil { !coordinatorService.setStatusInvocations.isEmpty }

        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, editContext: true))
        let vm = makeVM(service: service, coordinator: coordinator)

        async let appear: Void = vm.onAppear()
        // Let the VM resolve capability and park on the pending-mutation wait.
        await waitUntil { vm.canModerate != nil }
        await Task.yield()
        #expect(service.fetchCommentInvocations.isEmpty)

        coordinatorService.resolveSetStatus(callIndex: 0, with: makeDetail(id: 1, status: .approved))
        await appear
        _ = await mutation.value

        #expect(service.fetchCommentInvocations.isEmpty == false)
    }

    @Test func subscribedEventUpdatesLoadedStatus() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, status: .approved, editContext: true))
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = makeVM(service: service, coordinator: coordinator)

        await vm.onAppear()
        #expect(vm.header?.status == .approved)

        // A late status change for this comment arrives while the screen is open.
        coordinator.noteExternalStatus(id: 1, to: .spam)

        #expect(vm.header?.status == .spam)
    }

    @Test func trashConfirmationVariants() async {
        // nil replies -> generic confirmation.
        let unknownService = FakeCommentsService()
        unknownService.fetchCommentResult = .success(makeDetail(id: 1))
        unknownService.numberOfRepliesResult = .failure(FakeServiceError())
        let unknownVM = makeVM(service: unknownService)
        await unknownVM.onAppear()
        #expect(unknownVM.numberOfReplies == nil)
        #expect(unknownVM.trashConfirmation == .generic)

        // 0 replies -> no confirmation.
        let zeroService = FakeCommentsService()
        zeroService.fetchCommentResult = .success(makeDetail(id: 1))
        zeroService.numberOfRepliesResult = .success(0)
        let zeroVM = makeVM(service: zeroService)
        await zeroVM.onAppear()
        #expect(zeroVM.trashConfirmation == .none)

        // >0 replies -> reply-count confirmation.
        let manyService = FakeCommentsService()
        manyService.fetchCommentResult = .success(makeDetail(id: 1))
        manyService.numberOfRepliesResult = .success(3)
        let manyVM = makeVM(service: manyService)
        await manyVM.onAppear()
        #expect(manyVM.trashConfirmation == .withReplies)
    }

    @Test func actionsWaitForReplyCountAfterDetailRenders() async {
        let service = BlockingCommentsService()
        service.numberOfRepliesResult = nil
        let vm = makeVM(service: service)
        let detail = makeDetail(id: 1, editContext: true)

        async let appear: Void = vm.onAppear()
        await waitUntil { !service.fetchCommentInvocations.isEmpty }
        service.resolveFetch(callIndex: 0, with: detail)
        await waitUntil { !service.numberOfRepliesInvocations.isEmpty }

        // The comment is on screen while the count is still in flight, but
        // actions wait for it so a reply can't race a stale count.
        #expect(vm.content == .loaded(detail))
        #expect(!vm.isToolbarEnabled)
        #expect(vm.trashConfirmation == .generic)

        service.resolveNumberOfReplies(callIndex: 0, with: 3)
        await appear

        #expect(vm.isToolbarEnabled)
        #expect(vm.numberOfReplies == 3)
        #expect(vm.trashConfirmation == .withReplies)
    }

    @Test func parentPreviewLoadedForReply() async {
        let service = FakeCommentsService()
        service.fetchCommentResultsByID = [
            1: .success(makeDetail(id: 1, parent: 5)),
            5: .success(makeDetail(id: 5, status: .approved))
        ]
        let vm = makeVM(service: service)

        await vm.onAppear()

        #expect(vm.parentPreview?.id == 5)
        // The parent is fetched with view context regardless of capability.
        #expect(service.fetchCommentInvocations.contains { $0.id == 5 && $0.allowsEditContext == false })
    }

    @Test func parentFetchFailureHidesStrip() async {
        let service = FakeCommentsService()
        service.numberOfRepliesResult = .success(0)
        // 5 is missing: the parent fetch throws.
        service.fetchCommentResultsByID = [1: .success(makeDetail(id: 1, parent: 5))]
        let vm = makeVM(service: service)

        await vm.onAppear()

        #expect(vm.parentPreview == nil)
    }

    @Test func statusChangeWhileHiddenIsAppliedOnReturn() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, status: .approved, editContext: true))
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = makeVM(service: service, coordinator: coordinator)

        await vm.onAppear()
        #expect(vm.header?.status == .approved)

        // The screen is hidden because a parent detail was pushed on top. The
        // subscription is not torn down on disappearance, so a status change
        // that lands for this comment while it is hidden is still applied and is
        // reflected on return.
        coordinator.noteExternalStatus(id: 1, to: .spam)

        #expect(vm.header?.status == .spam)
    }

    // MARK: - Terminal (deleted) state

    @Test func deletedEventTerminatesAndLaterStatusChangeReenables() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, status: .approved, editContext: true))
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = makeVM(service: service, coordinator: coordinator)

        await vm.onAppear()
        #expect(vm.showsToolbar == true)

        // A permanent delete succeeds and its `.deleted` event terminates the
        // screen: the toolbar turns off.
        try? await coordinator.perform(.delete, on: makeDetail(id: 1, status: .approved))
        #expect(vm.isDeleted)
        #expect(vm.showsToolbar == false)

        // A later status change proves the comment exists again, clearing the
        // terminal state so the toolbar re-enables.
        coordinator.noteExternalStatus(id: 1, to: .approved)
        #expect(!vm.isDeleted)
        #expect(vm.showsToolbar == true)
    }

    @Test func deletedThenFailedRetryStaysTerminated() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, status: .approved, editContext: true))
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = makeVM(service: service, coordinator: coordinator)

        await vm.onAppear()
        try? await coordinator.perform(.delete, on: makeDetail(id: 1, status: .approved))
        #expect(vm.isDeleted)

        // The comment is genuinely gone: the retry fetch fails. It must surface
        // as failed and stay terminal rather than falsely re-enabling the
        // toolbar.
        service.fetchCommentResult = .failure(WpApiError.stub(statusCode: 404))
        await vm.retry()
        #expect(vm.content == .failed)
        #expect(vm.isDeleted)
        #expect(vm.showsToolbar == false)
    }

    // MARK: - Failure after deallocation

    @Test func failureAfterViewModelDeallocatedStillPresentsNotice() async {
        let noticePresenter = FakeNoticePresenter()
        let coordinatorService = BlockingCommentsService()
        let coordinator = CommentsModerationCoordinator(service: coordinatorService)
        var vm: CommentDetailViewModel? = await makeLoadedVM(status: .hold, coordinator: coordinator, noticePresenter: noticePresenter)
        vm!.perform(.approve)
        await waitUntil { !coordinatorService.setStatusInvocations.isEmpty }

        // The screen is torn down while the request is still in flight.
        vm = nil

        // The request then fails. The request task retains the app-wide
        // presenter even though the detail view model is gone.
        coordinatorService.failSetStatus(callIndex: 0, with: FakeServiceError())
        await waitUntil { !noticePresenter.presented.isEmpty }
        #expect(noticePresenter.presented == ["That action couldn't be completed. Please try again."])
    }
}
