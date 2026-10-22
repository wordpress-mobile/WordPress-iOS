import Testing
import WordPressAPI
import WordPressAPIInternal
@testable import WordPressComments

@MainActor
struct CommentReviewViewModelTests {
    @Test(arguments: [CommentModerationAction.approve, .spam, .trash])
    func confirmedSubmissionCountsOnceAndAdvances(_ action: CommentModerationAction) async {
        let service = loadedService()
        service.setStatusResult = .success(makeDetail(status: action == .approve ? .approved : .spam))
        let session = makeSession(service: service)
        await session.loadCurrent(id: 1)
        session.perform(action, id: 1)
        session.perform(action, id: 1)
        session.skip(id: 1)
        #expect(session.position == 0)
        #expect(!session.canSkip)
        await waitUntil { session.pendingAction == nil }
        #expect(session.position == 1)
        #expect(session.moderatedCount == 1)
        #expect(session.skippedCount == 0)
        #expect(service.setStatusInvocations.count + service.trashInvocations.count == 1)
        // Queued controls from the old view must not act on the next entry,
        // even after that entry has finished loading.
        await session.loadCurrent(id: 2)
        session.perform(action, id: 1)
        session.skip(id: 1)
        #expect(session.position == 1)
        #expect(session.pendingAction == nil)
    }

    @Test(arguments: [false, true])
    func unexpectedStatusHasNoCredit(remainsPending: Bool) async {
        let returnedStatus: CommentStatus = remainsPending ? .hold : .spam
        let service = loadedService()
        service.setStatusResult = .success(makeDetail(status: returnedStatus))
        let notices = FakeNoticePresenter()
        let session = makeSession(service: service, notices: notices)
        await session.loadCurrent(id: 1)
        session.perform(.approve, id: 1)
        await waitUntil { session.pendingAction == nil }
        #expect(session.moderatedCount == 0)
        #expect(session.position == (returnedStatus == .hold ? 0 : 1))
        #expect(notices.presented.count == (returnedStatus == .hold ? 1 : 0))
    }

    @Test func failedActionKeepsCurrentComment() async {
        let service = loadedService()
        let notices = FakeNoticePresenter()
        let session = makeSession(service: service, notices: notices)
        await session.loadCurrent(id: 1)
        session.perform(.approve, id: 1)
        await waitUntil { session.pendingAction == nil }
        #expect(session.position == 0)
        #expect(session.canModerate)
        #expect(notices.presented == [Strings.moderationFailed])
    }

    @Test func loadFailureRetainsHeaderAndCanRetryOrSkip() async {
        let service = loadedService()
        service.fetchCommentResultsByID[1] = .failure(FakeServiceError())
        let session = makeSession(service: service)
        await session.loadCurrent(id: 1)
        #expect(session.detail?.content == .failed)
        #expect(session.detail?.header?.authorName == "Author 1")
        #expect(!session.canModerate)
        #expect(session.canSkip)
        service.fetchCommentResultsByID[1] = .success(makeDetail(status: .hold, editContext: true))
        await session.loadCurrent(id: 1, retry: true)
        #expect(session.canModerate)
        session.skip(id: 1)
        #expect(session.skippedCount == 1)
        #expect(service.setStatusInvocations.isEmpty)
    }

    @Test func cannotModerateWithoutEditContext() async {
        let service = loadedService()
        service.fetchCommentResultsByID[1] = .success(makeDetail(status: .hold))
        let session = makeSession(service: service)
        session.perform(.approve, id: 1)
        await session.loadCurrent(id: 1)
        session.perform(.approve, id: 1)
        #expect(!session.canModerate)
        #expect(service.setStatusInvocations.isEmpty)
        #expect(session.canSkip)
    }

    @Test func missingAndPreviouslyHandledCommentsAreBypassed() async {
        let service = loadedService()
        service.fetchCommentResultsByID[1] = .failure(missingError())
        service.fetchCommentResultsByID[2] = .success(makeDetail(id: 2, status: .approved))
        let session = makeSession(service: service)
        await session.loadCurrent(id: 1)
        #expect(session.position == 1)
        await session.loadCurrent(id: 2)
        #expect(session.isComplete)
        #expect(session.moderatedCount == 0)
        #expect(session.skippedCount == 0)
    }

    @Test func sameStatusProbeConfirmsOwnSubmission() async {
        let service = loadedService()
        service.setStatusResult = .failure(WpApiError.stub(code: .CommentFailedEdit, statusCode: 500))
        service.fetchStatusResults = [.success(.approved)]
        let session = makeSession(service: service)
        await session.loadCurrent(id: 1)
        session.perform(.approve, id: 1)
        await waitUntil { session.pendingAction == nil }
        #expect(session.moderatedCount == 1)
        #expect(session.position == 1)
    }

    @Test(arguments: [false, true])
    func nonpendingProbeAfterFailureBypassesAndReconcilesList(closeDuringAction: Bool) async {
        let service = loadedService()
        service.queuedResults = [.success(makePage(items: items(), hasNext: false))]
        service.setStatusResult = .failure(WpApiError.stub(code: .CommentFailedEdit, statusCode: 500))
        service.fetchStatusResults = [.success(.spam)]
        let coordinator = CommentsModerationCoordinator(service: service)
        let notices = FakeNoticePresenter()
        let list = CommentsListViewModel(
            filter: .pending,
            service: service,
            changeEvents: coordinator.events.eraseToAnyPublisher()
        )
        await list.onAppear()
        let session = makeSession(service: service, coordinator: coordinator, notices: notices)
        await session.loadCurrent(id: 1)
        session.perform(.approve, id: 1)
        if closeDuringAction { session.close() }
        await waitUntil { !notices.presented.isEmpty }
        #expect(session.position == (closeDuringAction ? 0 : 1))
        #expect(session.isDismissed == closeDuringAction)
        #expect(session.moderatedCount == 0)
        #expect(session.skippedCount == 0)
        #expect(notices.presented == [Strings.moderationFailed])
        #expect(list.items.map(\.id) == [2])
    }

    @Test func externalEventsBypassFutureEntriesAndNeverRewriteSkips() async {
        let service = loadedService()
        let coordinator = CommentsModerationCoordinator(service: service)
        let session = makeSession(service: service, coordinator: coordinator)
        session.skip(id: 1)
        coordinator.noteExternalStatus(id: 1, to: .approved)
        coordinator.events.send(.deleted(id: 2))
        #expect(session.isComplete)
        #expect(session.outcomes[1] == .skipped)
        #expect(session.moderatedCount == 0)
        #expect(session.batch.count == 2)
    }

    @Test func skipDuringLoadingIgnoresOldResponseAndParent() async {
        let service = BlockingCommentsService()
        let session = makeSession(service: service)
        let firstLoad = Task { await session.loadCurrent(id: 1) }
        await waitUntil { service.fetchCommentInvocations.count == 1 }
        session.skip(id: 1)
        #expect(session.detail?.header?.authorName == "Author 2")
        #expect(session.detail?.content == .loading)
        service.resolveFetch(callIndex: 0, with: makeDetail(parent: 3, status: .hold, editContext: true))
        await waitUntil { service.fetchCommentInvocations.count == 2 }
        service.resolveFetch(callIndex: 1, with: makeDetail(id: 3))
        await firstLoad.value
        #expect(session.detail?.parentPreview == nil)
        #expect(session.detail?.trashConfirmation == .generic)
        #expect(session.position == 1)
        #expect(session.skippedCount == 1)
        #expect(service.callCount == 0)
    }

    @Test(arguments: [false, true])
    func closeDuringActionStillReconcilesPendingListAndReportsLateFailure(fails: Bool) async {
        let service = BlockingCommentsService()
        let coordinator = CommentsModerationCoordinator(service: service)
        let notices = FakeNoticePresenter()
        let list = CommentsListViewModel(
            filter: .pending,
            service: service,
            changeEvents: coordinator.events.eraseToAnyPublisher()
        )
        let listLoad = Task { await list.onAppear() }
        await waitUntil { service.callCount == 1 }
        service.resolve(callIndex: 0, with: makePage(items: items(), hasNext: false))
        await listLoad.value
        let session = makeSession(service: service, coordinator: coordinator, notices: notices)
        let load = Task { await session.loadCurrent(id: 1) }
        await waitUntil { service.fetchCommentInvocations.count == 1 }
        service.resolveFetch(callIndex: 0, with: makeDetail(status: .hold, editContext: true))
        await load.value
        session.perform(.approve, id: 1)
        await waitUntil { service.setStatusInvocations.count == 1 }
        session.close()
        if fails {
            service.failSetStatus(callIndex: 0, with: FakeServiceError())
        } else {
            service.resolveSetStatus(callIndex: 0, with: makeDetail(status: .approved))
        }
        await coordinator.waitForPendingMutation(id: 1)
        if fails { await waitUntil { !notices.presented.isEmpty } }
        #expect(session.isDismissed)
        #expect(!session.isComplete)
        #expect(session.detail == nil)
        #expect(session.moderatedCount == 0)
        #expect(list.items.map(\.id) == (fails ? [1, 2] : [2]))
        #expect(notices.presented.count == (fails ? 1 : 0))
    }

    @Test func eventsDuringSubmissionWaitForItsResult() async {
        let service = BlockingCommentsService()
        let coordinator = CommentsModerationCoordinator(service: service)
        let session = makeSession(service: service, coordinator: coordinator)
        let load = Task { await session.loadCurrent(id: 1) }
        await waitUntil { service.fetchCommentInvocations.count == 1 }
        service.resolveFetch(callIndex: 0, with: makeDetail(status: .hold, editContext: true))
        await load.value
        session.perform(.approve, id: 1)
        await waitUntil { service.setStatusInvocations.count == 1 }
        coordinator.noteExternalStatus(id: 1, to: .spam)
        #expect(session.position == 0)
        #expect(session.moderatedCount == 0)
        service.failSetStatus(callIndex: 0, with: FakeServiceError())
        await waitUntil { session.pendingAction == nil }
        #expect(session.position == 1)
        #expect(session.moderatedCount == 0)
    }

    @Test func oldTrashConfirmationCannotSubmitAgainstNextComment() async {
        let service = loadedService()
        service.numberOfRepliesResult = .success(2)
        let session = makeSession(service: service)
        await session.loadCurrent(id: 1)
        #expect(session.detail?.trashConfirmation == .withReplies)
        session.skip(id: 1)
        await session.loadCurrent(id: 2)
        // A confirmation retained by the old view still carries its old ID.
        session.perform(.trash, id: 1)
        #expect(service.trashInvocations.isEmpty)
    }

    @Test func completionCountsOnlyExplicitDecisions() async {
        let service = loadedService()
        service.setStatusResult = .success(makeDetail(status: .approved))
        let session = makeSession(service: service)
        await session.loadCurrent(id: 1)
        session.perform(.approve, id: 1)
        await waitUntil { session.pendingAction == nil }
        session.skip(id: 2)
        #expect(session.isComplete)
        #expect(session.moderatedCount == 1)
        #expect(session.skippedCount == 1)
        #expect(!session.canSkip)
        session.skip(id: 2)
        #expect(session.skippedCount == 1)
    }

    @Test func completionTextOmitsZeroCounts() {
        #expect(Strings.Review.summary(moderated: 0, skipped: 0) == "No comments moderated in this session.")
        #expect(Strings.Review.summary(moderated: 1, skipped: 0) == "1 comment moderated.")
        #expect(Strings.Review.summary(moderated: 3, skipped: 0) == "3 comments moderated.")
        #expect(Strings.Review.summary(moderated: 0, skipped: 1) == "1 comment skipped.")
        #expect(Strings.Review.summary(moderated: 0, skipped: 5) == "5 comments skipped.")
        #expect(Strings.Review.summary(moderated: 3, skipped: 2) == "3 comments moderated. 2 skipped.")
    }

    @Test func closeDuringLoadingCannotAdvanceOrCompleteLater() async {
        let service = BlockingCommentsService()
        let session = makeSession(service: service)
        let load = Task { await session.loadCurrent(id: 1) }
        await waitUntil { service.fetchCommentInvocations.count == 1 }
        session.close()
        service.resolveFetch(callIndex: 0, with: makeDetail(status: .approved))
        await load.value
        #expect(session.isDismissed)
        #expect(!session.isComplete)
        #expect(session.position == 0)
        #expect(session.outcomes.isEmpty)
    }

    @Test func allSkippedSessionCompletesAndFreshSessionIncludesSkippedComments() {
        let service = loadedService()
        let session = makeSession(service: service)
        session.skip(id: 1)
        session.skip(id: 2)
        #expect(session.isComplete)
        #expect(session.moderatedCount == 0)
        #expect(session.skippedCount == 2)
        session.close()
        let fresh = makeSession(service: service)
        #expect(fresh.detail?.commentID == 1)
        #expect(fresh.skippedCount == 0)
        #expect(service.setStatusInvocations.isEmpty)
    }

    @Test func disappearingDuringSubmissionBypassesWithoutCredit() async {
        let service = loadedService()
        service.setStatusResult = .failure(missingError())
        let session = makeSession(service: service)
        await session.loadCurrent(id: 1)
        session.perform(.approve, id: 1)
        await waitUntil { session.pendingAction == nil }
        #expect(session.position == 1)
        #expect(session.moderatedCount == 0)
        #expect(session.outcomes[1] == .bypassed)
    }

    private func items() -> [CommentListItem] {
        [makeItem(id: 1, authorName: "Author 1", status: .hold), makeItem(id: 2, authorName: "Author 2", status: .hold)]
    }

    private func loadedService() -> FakeCommentsService {
        let service = FakeCommentsService()
        for id: Int64 in [1, 2] {
            service.fetchCommentResultsByID[id] = .success(makeDetail(id: id, status: .hold, editContext: true))
        }
        service.numberOfRepliesResult = .success(0)
        return service
    }

    private func makeSession(
        service: any CommentsServiceProtocol,
        coordinator: CommentsModerationCoordinator? = nil,
        notices: FakeNoticePresenter = FakeNoticePresenter()
    ) -> CommentReviewViewModel {
        let coordinator = coordinator ?? CommentsModerationCoordinator(service: service)
        return CommentReviewViewModel(batch: items(), coordinator: coordinator, noticePresenter: notices) { item in
            makeVM(commentID: item.id, seed: item, service: service, coordinator: coordinator)
        }
    }

    private func missingError() -> WpApiError {
        .stub(statusCode: 404)
    }
}
