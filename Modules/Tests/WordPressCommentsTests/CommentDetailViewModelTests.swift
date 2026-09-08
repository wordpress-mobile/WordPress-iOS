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
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = await makeLoadedVM(status: .approved, coordinator: coordinator)

        #expect(vm.header?.status == .approved)

        // A late status change for this comment arrives while the screen is open.
        coordinator.noteExternalStatus(id: 1, to: .spam)

        #expect(vm.header?.status == .spam)
    }

    @Test func contentChangedEventUpdatesLoadedDetail() async {
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = await makeLoadedVM(status: .approved, coordinator: coordinator)

        let headerBeforeEvent = vm.header

        coordinator.events.send(.contentChanged(id: vm.commentID, contentHTML: "<p>edited</p>", contentRaw: "edited"))

        guard case .loaded(let detail) = vm.content else {
            Issue.record("Expected loaded content")
            return
        }
        #expect(detail.contentHTML == "<p>edited</p>")
        #expect(detail.contentRaw == "edited")
        #expect(vm.header == headerBeforeEvent)
        #expect(!vm.isDeleted)
    }

    @Test func replyCreatedEventLeavesDetailUntouched() async {
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = await makeLoadedVM(status: .approved, coordinator: coordinator)

        let contentBeforeEvent = vm.content
        let headerBeforeEvent = vm.header

        coordinator.events.send(.replyCreated(parentID: vm.commentID, replyStatus: .approved))

        #expect(vm.content == contentBeforeEvent)
        #expect(vm.header == headerBeforeEvent)
        #expect(!vm.isDeleted)
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

    @Test func replyCreatedIncrementsKnownReplyCountAndUpdatesTrashConfirmation() async {
        // Seed a zero known reply count via the load path's count fetch, so
        // trashConfirmation starts at .none.
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, status: .approved, editContext: true))
        service.numberOfRepliesResult = .success(0)
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = makeVM(service: service, coordinator: coordinator)

        await vm.onAppear()
        #expect(vm.numberOfReplies == 0)
        #expect(vm.trashConfirmation == .none)

        // This screen's own comment just gained a reply: the cached count must
        // be bumped, or a parent that just went from 0 to 1 replies could be
        // trashed with no confirmation.
        coordinator.events.send(.replyCreated(parentID: vm.commentID, replyStatus: .approved))

        #expect(vm.numberOfReplies == 1)
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

    @Test func parentContentEditRefreshesInReplyToStrip() async {
        let service = FakeCommentsService()
        service.numberOfRepliesResult = .success(0)
        service.fetchCommentResultsByID = [
            1: .success(makeDetail(id: 1, parent: 5)),
            5: .success(makeDetail(id: 5, status: .approved))
        ]
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = makeVM(service: service, coordinator: coordinator)

        await vm.onAppear()
        #expect(vm.parentPreview?.id == 5)

        // The parent's own detail screen edits its content; this screen never
        // subscribed to the child's id for that event, so it must also react
        // to the parent's id to keep the "In reply to" strip fresh.
        coordinator.events.send(
            .contentChanged(id: 5, contentHTML: "<p>edited parent</p>", contentRaw: "edited parent")
        )

        #expect(vm.parentPreview?.snippet == "edited parent")
    }

    @Test func contentChangedForOwnIDStillUpdatesOwnContentWithParentSubscribed() async {
        // Guards against the parent-content fix accidentally routing the
        // child's own contentChanged event through the parent handler (or vice
        // versa): both must keep working independently.
        let service = FakeCommentsService()
        service.numberOfRepliesResult = .success(0)
        service.fetchCommentResultsByID = [
            1: .success(makeDetail(id: 1, parent: 5, status: .approved, editContext: true)),
            5: .success(makeDetail(id: 5, status: .approved))
        ]
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = makeVM(service: service, coordinator: coordinator)

        await vm.onAppear()
        let parentPreviewBeforeEvent = vm.parentPreview

        coordinator.events.send(.contentChanged(id: vm.commentID, contentHTML: "<p>edited</p>", contentRaw: "edited"))

        guard case .loaded(let detail) = vm.content else {
            Issue.record("Expected loaded content")
            return
        }
        #expect(detail.contentHTML == "<p>edited</p>")
        #expect(vm.parentPreview == parentPreviewBeforeEvent)
    }

    @Test func topLevelCommentHasNoParentSubscriptionAndDoesNotCrash() async {
        // parent: 0 in makeDetail means no parentID (top-level comment).
        let service = FakeCommentsService()
        service.numberOfRepliesResult = .success(0)
        service.fetchCommentResultsByID = [1: .success(makeDetail(id: 1, status: .approved))]
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = makeVM(service: service, coordinator: coordinator)

        await vm.onAppear()
        #expect(vm.parentPreview == nil)

        // No parent subscription should exist; broadcasting a contentChanged
        // for some other id must not affect (or crash) this screen.
        coordinator.events.send(.contentChanged(id: 999, contentHTML: "<p>irrelevant</p>", contentRaw: "irrelevant"))

        #expect(vm.parentPreview == nil)
    }

    @Test func statusChangeWhileHiddenIsAppliedOnReturn() async {
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = await makeLoadedVM(status: .approved, coordinator: coordinator)

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
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = await makeLoadedVM(status: .approved, coordinator: coordinator)

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

    // MARK: - Reply/edit composer gating and presentation

    @Test func canReplyRequiresModerationAndActiveStatus() async {
        let approvedVM = await makeLoadedVM(status: .approved)
        #expect(approvedVM.canReply == true)

        let pendingVM = await makeLoadedVM(status: .hold)
        #expect(pendingVM.canReply == true)

        let spamVM = await makeLoadedVM(status: .spam)
        #expect(spamVM.canReply == false)

        let trashVM = await makeLoadedVM(status: .trash)
        #expect(trashVM.canReply == false)

        let otherVM = await makeLoadedVM(status: .custom("draft"))
        #expect(otherVM.canReply == false)

        // A demoted capability hides the toolbar (and so blocks reply)
        // regardless of the loaded status.
        let cannotModerateCapabilities = FakeCommentsCapabilities()
        cannotModerateCapabilities.canModerate = false
        let cannotModerateService = FakeCommentsService()
        cannotModerateService.fetchCommentResult = .success(makeDetail(id: 1, status: .approved, editContext: false))
        let cannotModerateVM = makeVM(service: cannotModerateService, capabilities: cannotModerateCapabilities)
        await cannotModerateVM.onAppear()
        #expect(cannotModerateVM.canReply == false)

        // Before the authoritative fetch lands (seed only), canReply is false.
        let seed = makeItem(id: 1, status: .approved)
        let unfetchedVM = makeVM(seed: seed, service: FakeCommentsService())
        #expect(unfetchedVM.canReply == false)
    }

    @Test func knownCapabilityGatesControlsBeforeAppear() async {
        let vm = makeVM(
            seed: makeItem(id: 1, status: .approved),
            service: BlockingCommentsService(),
            resolver: await makeResolvedCapabilities(canModerate: true)
        )

        // No await has run yet: the toolbar, Reply, and Edit already render
        // (disabled), so they take part in the push transition.
        #expect(vm.showsToolbar)
        #expect(vm.toolbarModel == .approved)
        #expect(vm.showsReply)
        #expect(vm.showsEdit)
        #expect(!vm.isToolbarEnabled)
        #expect(!vm.canReply)

        let readOnlyVM = makeVM(
            seed: makeItem(id: 1, status: .approved),
            service: BlockingCommentsService(),
            resolver: await makeResolvedCapabilities(canModerate: false)
        )
        #expect(!readOnlyVM.showsToolbar)
        #expect(!readOnlyVM.showsReply)
    }

    @Test func knownCapabilitySkipsTheLookupAndFailedLookupDegradesToReadOnly() async {
        let capabilities = FakeCommentsCapabilities()
        let resolver = CommentsCapabilityResolver(capabilities: capabilities)
        _ = await resolver.resolve()
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 1, editContext: true))
        let vm = makeVM(service: service, resolver: resolver)
        await vm.onAppear()
        #expect(capabilities.invocations == 1) // the resolver's, not a second one
        #expect(vm.canModerate == true)

        let failing = FakeCommentsCapabilities()
        failing.error = FakeServiceError()
        let readOnlyService = FakeCommentsService()
        readOnlyService.fetchCommentResult = .success(makeDetail(id: 1))
        let readOnlyVM = makeVM(service: readOnlyService, capabilities: failing)
        await readOnlyVM.onAppear()
        #expect(readOnlyVM.canModerate == false)
        #expect(readOnlyService.fetchCommentInvocations.last?.allowsEditContext == false)
    }

    @Test func showsReplyRendersDisabledButtonBeforeFetchCompletes() async {
        let service = BlockingCommentsService()
        let vm = makeVM(seed: makeItem(id: 1, status: .approved), service: service)
        // Capability unresolved: nothing renders yet.
        #expect(!vm.showsReply)

        async let appear: Void = vm.onAppear()
        await waitUntil { !service.fetchCommentInvocations.isEmpty }

        // Capability resolved, fetch in flight: the button renders from the
        // seed status but stays disabled, like the toolbar.
        #expect(vm.showsReply)
        #expect(!vm.canReply)

        service.resolveFetch(callIndex: 0, with: makeDetail(id: 1, editContext: true))
        await appear

        #expect(vm.showsReply)
        #expect(vm.canReply)
    }

    @Test func showsReplyHiddenForBinnedAndCustomStatuses() async {
        for status in [CommentStatus.spam, .trash, .custom("draft")] {
            let service = FakeCommentsService()
            service.fetchCommentResult = .success(makeDetail(id: 1, status: status, editContext: true))
            let vm = makeVM(seed: makeItem(id: 1, status: status), service: service)
            await vm.onAppear()
            #expect(!vm.showsReply, "\(status)")
        }
    }

    @Test func showsEditRendersDisabledItemBeforeFetchCompletes() async {
        let service = BlockingCommentsService()
        let vm = makeVM(seed: makeItem(id: 1, status: .trash), service: service)
        #expect(!vm.showsEdit)

        async let appear: Void = vm.onAppear()
        await waitUntil { !service.fetchCommentInvocations.isEmpty }

        // Spam/trash stay editable, so the item shows (disabled) from the
        // seed; only a custom status hides it.
        #expect(vm.showsEdit)
        #expect(!vm.canEdit)

        service.resolveFetch(callIndex: 0, with: makeDetail(id: 1, status: .trash, editContext: true))
        await appear

        #expect(vm.showsEdit)
        #expect(vm.canEdit)

        let customVM = makeVM(seed: makeItem(id: 1, status: .custom("draft")), service: FakeCommentsService())
        await customVM.onAppear()
        #expect(!customVM.showsEdit)
    }

    @Test func shareLinkComesFromSeedBeforeFetchAndOnlyForApproved() async {
        let seed = makeItem(id: 1, status: .approved)
        let service = BlockingCommentsService()
        let vm = makeVM(seed: seed, service: service)
        // Sharing needs no capability or fetch: the seed's link is enough.
        #expect(vm.shareLink == seed.link)

        async let appear: Void = vm.onAppear()
        await waitUntil { !service.fetchCommentInvocations.isEmpty }
        let detail = makeDetail(id: 1, editContext: true)
        service.resolveFetch(callIndex: 0, with: detail)
        await appear
        #expect(vm.shareLink == detail.link)

        for status in [CommentStatus.hold, .spam, .trash, .custom("draft")] {
            let hiddenService = FakeCommentsService()
            hiddenService.fetchCommentResult = .success(makeDetail(id: 1, status: status, editContext: true))
            let hiddenVM = makeVM(seed: makeItem(id: 1, status: status), service: hiddenService)
            #expect(hiddenVM.shareLink == nil, "\(status) seed")
            await hiddenVM.onAppear()
            #expect(hiddenVM.shareLink == nil, "\(status) fetched")
        }
    }

    @Test func canEditRequiresEditContextAndModeledStatus() async {
        let vm = await makeLoadedVM(status: .approved)
        #expect(vm.canEdit == true)

        // A stale capability that fell back to view context (no edit context)
        // already hides the toolbar; canEdit follows.
        let noEditContextService = FakeCommentsService()
        noEditContextService.fetchCommentResult = .success(makeDetail(id: 1, status: .approved, editContext: false))
        let noEditContextVM = makeVM(service: noEditContextService)
        await noEditContextVM.onAppear()
        #expect(noEditContextVM.canEdit == false)

        // A custom, non-modeled status is not editable.
        let otherVM = await makeLoadedVM(status: .custom("draft"))
        #expect(otherVM.canEdit == false)

        let cannotModerateCapabilities = FakeCommentsCapabilities()
        cannotModerateCapabilities.canModerate = false
        let cannotModerateService = FakeCommentsService()
        cannotModerateService.fetchCommentResult = .success(makeDetail(id: 1, status: .approved, editContext: false))
        let cannotModerateVM = makeVM(service: cannotModerateService, capabilities: cannotModerateCapabilities)
        await cannotModerateVM.onAppear()
        #expect(cannotModerateVM.canEdit == false)
    }

    // MARK: - Status change refreshes the loaded detail (not just the header)

    @Test(arguments: [CommentListItem.Status.spam, .trash])
    func statusChangeToSpamOrTrashRefreshesCanReplyGating(_ to: CommentListItem.Status) async {
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = await makeLoadedVM(status: .approved, coordinator: coordinator)

        #expect(vm.canReply == true)
        #expect(vm.canEdit == true)

        coordinator.noteExternalStatus(id: 1, to: to)

        // The header (the screen's display source of truth) still tracks the
        // new status, matching the existing header-tracking behavior.
        #expect(vm.header?.status == to)
        // canReply reads loadedDetail.status directly and excludes spam/trash;
        // it must follow moderation instead of staying stuck on the
        // pre-moderation status (Reply no longer shown for a spam/trash
        // comment).
        #expect(vm.canReply == false)
        // canEdit's guard only excludes a custom, non-modeled status (`.other`);
        // spam/trash remain intentionally editable, so canEdit is unaffected
        // here. The loaded detail's status still refreshed correctly, which the
        // next test demonstrates via the case canEdit's guard DOES react to.
        #expect(vm.canEdit == true)
    }

    @Test func statusChangeToPendingKeepsCanReplyTrue() async {
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = await makeLoadedVM(status: .approved, coordinator: coordinator)

        #expect(vm.canReply == true)

        coordinator.noteExternalStatus(id: 1, to: .pending)

        #expect(vm.header?.status == .pending)
        #expect(vm.canReply == true)
    }

    @Test func statusChangeAwayFromCustomStatusRefreshesCanEditGating() async {
        // canEdit's guard only excludes a custom, non-modeled status (`.other`).
        // Load with a custom status (canEdit false), then reconcile back to a
        // modeled status: without the loadedDetail refresh, canEdit would stay
        // stuck reading the stale `.other` status and never re-enable.
        let coordinator = CommentsModerationCoordinator(service: FakeCommentsService())
        let vm = await makeLoadedVM(status: .custom("draft"), coordinator: coordinator)

        #expect(vm.canEdit == false)

        coordinator.noteExternalStatus(id: 1, to: .approved)

        #expect(vm.header?.status == .approved)
        #expect(vm.canEdit == true)
    }

    @Test func replyTappedPresentsReplyComposer() async {
        let vm = await makeLoadedVM(status: .approved)
        #expect(vm.canReply == true)

        vm.replyTapped()

        #expect(vm.composer != nil)
        #expect(vm.composer?.mode == .reply(parent: vm.loadedDetail!))
    }

    @Test func editTappedPresentsEditComposer() async {
        let vm = await makeLoadedVM(status: .approved)
        #expect(vm.canEdit == true)

        vm.editTapped()

        #expect(vm.composer != nil)
        #expect(vm.composer?.mode == .edit(comment: vm.loadedDetail!))
    }

    @Test func replyTappedIgnoredWhileMutating() async {
        let coordinatorService = BlockingCommentsService()
        let coordinator = CommentsModerationCoordinator(service: coordinatorService)
        let vm = await makeLoadedVM(status: .approved, coordinator: coordinator)

        let spam = Task {
            try? await coordinator.perform(.spam, on: makeDetail(id: 1, status: .approved, editContext: true))
        }
        await waitUntil { !coordinatorService.setStatusInvocations.isEmpty }
        #expect(coordinator.isMutating(id: 1))

        vm.replyTapped()

        #expect(vm.composer == nil)

        coordinatorService.resolveSetStatus(callIndex: 0, with: makeDetail(id: 1, status: .spam, editContext: true))
        _ = await spam.value
    }

    @Test func composerClosedRepliedPresentsNoticeAndDismisses() async {
        let noticePresenter = FakeNoticePresenter()
        let vm = await makeLoadedVM(status: .approved, noticePresenter: noticePresenter)
        vm.replyTapped()
        #expect(vm.composer != nil)

        vm.composerClosed(.replied(notice: "Reply sent."))

        #expect(vm.composer == nil)
        #expect(noticePresenter.presented == ["Reply sent."])
    }

    @Test(arguments: [CommentComposerViewModel.Outcome.edited, nil])
    func composerClosedEditedOrCancelledJustDismisses(_ outcome: CommentComposerViewModel.Outcome?) async {
        let noticePresenter = FakeNoticePresenter()
        let vm = await makeLoadedVM(status: .approved, noticePresenter: noticePresenter)
        vm.editTapped()
        #expect(vm.composer != nil)

        vm.composerClosed(outcome)

        #expect(vm.composer == nil)
        #expect(noticePresenter.presented.isEmpty)
    }
}
