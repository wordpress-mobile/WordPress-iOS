import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal
@testable import WordPressComments

@MainActor
struct CommentsModerationCoordinatorTests {
    @Test func noEventEmittedBeforeRequestResolves() async {
        let service = BlockingCommentsService()
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        async let performed: Void = coordinator.perform(.approve, on: makeDetail(id: 1, status: .hold))
        await waitUntil { !service.setStatusInvocations.isEmpty }

        // Still blocked on the continuation: nothing emitted until it resolves.
        #expect(recorder.events.isEmpty)

        service.resolveSetStatus(callIndex: 0, with: makeDetail(id: 1, status: .approved))
        _ = try? await performed
        #expect(recorder.events == [.statusChanged(id: 1, to: .approved)])
    }

    @Test func successEmitsLandedStatusFromResponse() async {
        let service = FakeCommentsService()
        // Restore probes first and finds the comment still in the bin, so it
        // issues the restore; it lands back on approved (the saved pre-trash
        // status), not the pending stand-in.
        service.fetchStatusResults = [.success(.spam)]
        service.setStatusResult = .success(makeDetail(id: 1, status: .approved))
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        try? await coordinator.perform(.restore, on: makeDetail(id: 1, status: .spam))

        #expect(recorder.events == [.statusChanged(id: 1, to: .approved)])
        #expect(service.restoreInvocations.map(\.from) == [.spam])
    }

    @Test func trashSuccessEmitsTrashEvent() async {
        let service = FakeCommentsService() // trash() succeeds when no error queued
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        try? await coordinator.perform(.trash, on: makeDetail(id: 1, status: .approved))

        #expect(recorder.events == [.statusChanged(id: 1, to: .trash)])
    }

    @Test func deleteSuccessEmitsDeletedEvent() async {
        let service = FakeCommentsService() // delete() succeeds when no error queued
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        try? await coordinator.perform(.delete, on: makeDetail(id: 1, status: .approved))

        #expect(recorder.events == [.deleted(id: 1)])
    }

    @Test func genuineFailureThrowsAndEmitsNothing() async {
        let service = FakeCommentsService()
        service.setStatusResult = .failure(FakeServiceError())
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        await #expect(throws: (any Error).self) {
            try await coordinator.perform(.approve, on: makeDetail(id: 1, status: .hold))
        }
        #expect(recorder.events.isEmpty)
    }

    @Test func commentFailedEditProbeMatchIsSuccess() async {
        let service = FakeCommentsService()
        service.setStatusResult = .failure(WpApiError.stub(code: .CommentFailedEdit))
        // The probe finds the comment already approved (an earlier timed-out
        // attempt landed, or another moderator made the same change).
        service.fetchStatusResults = [.success(.approved)]
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        await #expect(throws: Never.self) {
            try await coordinator.perform(.approve, on: makeDetail(id: 1, status: .hold))
        }
        #expect(recorder.events == [.statusChanged(id: 1, to: .approved)])
    }

    @Test func commentFailedEditProbeMismatchThrowsWithoutEvent() async {
        let service = FakeCommentsService()
        service.setStatusResult = .failure(WpApiError.stub(code: .CommentFailedEdit))
        // The probe finds a different status: the action genuinely failed.
        service.fetchStatusResults = [.success(.spam)]
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        await #expect(throws: (any Error).self) {
            try await coordinator.perform(.approve, on: makeDetail(id: 1, status: .hold))
        }
        #expect(recorder.events.isEmpty)
    }

    @Test func commentFailedEditProbeFailureThrowsOriginalError() async {
        let service = FakeCommentsService()
        service.setStatusResult = .failure(WpApiError.stub(code: .CommentFailedEdit))
        // The probe itself fails: fall through to the original error, no event.
        service.fetchStatusResults = [.failure(FakeServiceError())]
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        var caught: Error?
        do {
            try await coordinator.perform(.approve, on: makeDetail(id: 1, status: .hold))
        } catch {
            caught = error
        }

        #expect((caught as? WpApiError)?.wpErrorCode == .CommentFailedEdit)
        #expect(recorder.events.isEmpty)
    }

    @Test func restoreProbeAlreadyActiveSkipsRequest() async {
        let service = FakeCommentsService()
        // The pre-restore probe finds the comment already active: an earlier
        // attempt landed (its response was lost). Restore is non-idempotent, so
        // it must NOT be reissued; the probed status is the outcome and no
        // restore request goes out.
        service.fetchStatusResults = [.success(.approved)]
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        await #expect(throws: Never.self) {
            try await coordinator.perform(.restore, on: makeDetail(id: 1, status: .spam))
        }
        #expect(recorder.events == [.statusChanged(id: 1, to: .approved)])
        #expect(service.fetchStatusInvocations == [1])
        #expect(service.restoreInvocations.isEmpty)
    }

    @Test func restoreProbeStillInBinIssuesRestore() async {
        let service = FakeCommentsService()
        // The probe proves the comment is still in the bin, so the restore is
        // safe to issue; it lands back on its saved pre-trash status.
        service.fetchStatusResults = [.success(.trash)]
        service.setStatusResult = .success(makeDetail(id: 1, status: .approved))
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        await #expect(throws: Never.self) {
            try await coordinator.perform(.restore, on: makeDetail(id: 1, status: .trash))
        }
        #expect(recorder.events == [.statusChanged(id: 1, to: .approved)])
        #expect(service.restoreInvocations.map(\.from) == [.trash])
    }

    @Test func restoreUsesProbedBinNotStaleHeader() async {
        let service = FakeCommentsService()
        // The tap captured spam, but the comment was moved to trash meanwhile.
        // The restore must target the probed bin (untrash), not the stale
        // header (unspam), so the right restore hooks run.
        service.fetchStatusResults = [.success(.trash)]
        service.setStatusResult = .success(makeDetail(id: 1, status: .approved))
        let coordinator = CommentsModerationCoordinator(service: service)

        try? await coordinator.perform(.restore, on: makeDetail(id: 1, status: .spam))

        #expect(service.restoreInvocations.map(\.from) == [.trash])
    }

    @Test func restoreProbeFailureDoesNotIssueRestore() async {
        let service = FakeCommentsService()
        // The pre-restore probe fails, so the comment's state is unconfirmed.
        // Issuing the restore anyway could downgrade an already-restored
        // comment, so it must not go out: the action fails instead.
        service.fetchStatusResults = [.failure(FakeServiceError())]
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        await #expect(throws: (any Error).self) {
            try await coordinator.perform(.restore, on: makeDetail(id: 1, status: .trash))
        }
        #expect(recorder.events.isEmpty)
        #expect(service.restoreInvocations.isEmpty)
    }

    @Test func trashAlreadyTrashedIsSuccess() async {
        let service = FakeCommentsService()
        service.trashError = WpApiError.stub(code: .AlreadyTrashed)
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        await #expect(throws: Never.self) {
            try await coordinator.perform(.trash, on: makeDetail(id: 1, status: .approved))
        }
        #expect(recorder.events == [.statusChanged(id: 1, to: .trash)])
    }

    @Test func notFoundOnDeleteIsSuccessWithDeletedEvent() async {
        let service = FakeCommentsService()
        service.deleteError = WpApiError.stub(statusCode: 404)
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        await #expect(throws: Never.self) {
            try await coordinator.perform(.delete, on: makeDetail(id: 1, status: .approved))
        }
        #expect(recorder.events == [.deleted(id: 1)])
    }

    @Test func notFoundOnNonDeleteThrowsWithDeletedEvent() async {
        let service = FakeCommentsService()
        service.setStatusResult = .failure(WpApiError.stub(statusCode: 404))
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        await #expect(throws: (any Error).self) {
            try await coordinator.perform(.approve, on: makeDetail(id: 1, status: .hold))
        }
        #expect(recorder.events == [.deleted(id: 1)])
    }

    @Test func secondPerformWhileInFlightIsIgnored() async {
        let service = BlockingCommentsService()
        let coordinator = CommentsModerationCoordinator(service: service)
        let recorder = EventRecorder(coordinator)

        async let first: Void = coordinator.perform(.approve, on: makeDetail(id: 1, status: .hold))
        await waitUntil { !service.setStatusInvocations.isEmpty }

        // A second action while the first is in flight returns without a request.
        try? await coordinator.perform(.spam, on: makeDetail(id: 1, status: .hold))
        #expect(service.setStatusInvocations.count == 1)

        service.resolveSetStatus(callIndex: 0, with: makeDetail(id: 1, status: .approved))
        _ = try? await first
        #expect(recorder.events == [.statusChanged(id: 1, to: .approved)])
    }

    @Test func waitForPendingMutationSuspendsUntilSettled() async {
        let service = BlockingCommentsService()
        let coordinator = CommentsModerationCoordinator(service: service)

        async let performed: Void = coordinator.perform(.approve, on: makeDetail(id: 1, status: .hold))
        await waitUntil { !service.setStatusInvocations.isEmpty }

        async let waiterResumed: Bool = {
            await coordinator.waitForPendingMutation(id: 1)
            return true
        }()

        // Let the waiter reach its suspension point; the mutation is still in
        // flight, so it must not have resumed yet.
        await Task.yield()
        #expect(coordinator.isMutating(id: 1))

        service.resolveSetStatus(callIndex: 0, with: makeDetail(id: 1, status: .approved))
        #expect(await waiterResumed)
        _ = try? await performed
        #expect(!coordinator.isMutating(id: 1))
    }

    @Test func mappedSuccessStillFiresAnalytics() async {
        let spy = SpyCommentsTracker()
        let service = FakeCommentsService()
        service.setStatusResult = .failure(WpApiError.stub(code: .CommentFailedEdit))
        service.fetchStatusResults = [.success(.approved)]
        let coordinator = CommentsModerationCoordinator(service: service, tracker: spy)

        try? await coordinator.perform(.approve, on: makeDetail(id: 1, status: .hold))

        // A mapped success fires the same analytics event as a plain success.
        #expect(spy.trackedEvents == [.approved(commentID: 1, postID: 10)])
    }
}
