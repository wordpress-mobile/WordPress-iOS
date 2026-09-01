import Foundation
import Testing
import WordPressAPI
@testable import WordPressComments

@MainActor
struct CommentsAnalyticsTests {
    // MARK: - detailViewed

    @Test func detailViewedFiresOnceOnFirstSuccessfulFetch() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .success(makeDetail(id: 7, post: 42))
        service.numberOfRepliesResult = .success(0)
        let spy = SpyCommentsTracker()
        let vm = makeVM(commentID: 7, service: service, tracker: spy)

        await vm.onAppear()
        // A second appearance is a no-op after the first success; the event must
        // not fire twice.
        await vm.onAppear()

        #expect(spy.trackedEvents == [.detailViewed(commentID: 7, postID: 42)])
    }

    @Test func detailViewedDoesNotFireWhenFetchFails() async {
        let service = FakeCommentsService()
        service.fetchCommentResult = .failure(FakeServiceError())
        let spy = SpyCommentsTracker()
        let vm = makeVM(commentID: 7, service: service, tracker: spy)

        await vm.onAppear()

        #expect(spy.trackedEvents.isEmpty)
    }

    // MARK: - action events

    @Test(arguments: [
        (CommentModerationAction.approve, CommentStatus.approved, CommentsTrackedEvent.approved(commentID: 1, postID: 10)),
        (.unapprove, .hold, .unapproved(commentID: 1, postID: 10)),
        (.spam, .spam, .spammed(commentID: 1, postID: 10))
    ])
    func statusWriteTracksItsEventOnSuccess(
        action: CommentModerationAction,
        landed: CommentStatus,
        expected: CommentsTrackedEvent
    ) async {
        let spy = SpyCommentsTracker()
        let service = FakeCommentsService()
        service.setStatusResult = .success(makeDetail(id: 1, post: 10, status: landed))
        let coordinator = CommentsModerationCoordinator(service: service, tracker: spy)

        try? await coordinator.perform(action, on: makeDetail(id: 1, post: 10))

        #expect(spy.trackedEvents == [expected])
    }

    @Test func trashTracksTrashedOnSuccess() async {
        let spy = SpyCommentsTracker()
        let service = FakeCommentsService()
        // trash() succeeds when no error is queued.
        let coordinator = CommentsModerationCoordinator(service: service, tracker: spy)

        try? await coordinator.perform(.trash, on: makeDetail(id: 1, post: 10, status: .approved))

        #expect(spy.trackedEvents == [.trashed(commentID: 1, postID: 10)])
    }

    @Test func restoreIsNotTracked() async {
        let spy = SpyCommentsTracker()
        let service = FakeCommentsService()
        // Restore probes first; the comment is still in the bin, so it issues.
        service.fetchStatusResults = [.success(.spam)]
        service.setStatusResult = .success(makeDetail(id: 1, post: 10, status: .approved))
        let coordinator = CommentsModerationCoordinator(service: service, tracker: spy)

        try? await coordinator.perform(.restore, on: makeDetail(id: 1, post: 10, status: .spam))

        #expect(spy.trackedEvents.isEmpty)
    }

    @Test func deleteIsNotTracked() async {
        let spy = SpyCommentsTracker()
        let service = FakeCommentsService()
        let coordinator = CommentsModerationCoordinator(service: service, tracker: spy)

        try? await coordinator.perform(.delete, on: makeDetail(id: 1, post: 10, status: .trash))

        #expect(spy.trackedEvents.isEmpty)
    }

    @Test func failedActionIsNotTracked() async {
        let spy = SpyCommentsTracker()
        let service = FakeCommentsService()
        // A genuine failure (no error code and no 404): the action definitively
        // did not succeed, so nothing is tracked.
        service.setStatusResult = .failure(FakeServiceError())
        let coordinator = CommentsModerationCoordinator(service: service, tracker: spy)

        try? await coordinator.perform(.approve, on: makeDetail(id: 1, post: 10, status: .hold))

        #expect(spy.trackedEvents.isEmpty)
    }
}
