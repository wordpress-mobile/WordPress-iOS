import Combine
import Foundation
import WordPressAPIInternal

/// A moderation action the user can trigger on a comment. Restore covers both
/// unspam and untrash; the coordinator probes which bin the comment is in
/// before issuing the matching core operation.
enum CommentModerationAction: Hashable, Sendable {
    case approve // pending -> approved
    case unapprove // approved -> pending
    case spam
    case trash
    case restore
    case delete

    /// The analytics event for a successful run. Restore and delete map to no
    /// event (legacy parity: those actions have no analytics event).
    func trackedEvent(commentID: Int64, postID: Int64) -> CommentsTrackedEvent? {
        switch self {
        case .approve: .approved(commentID: commentID, postID: postID)
        case .unapprove: .unapproved(commentID: commentID, postID: postID)
        case .spam: .spammed(commentID: commentID, postID: postID)
        case .trash: .trashed(commentID: commentID, postID: postID)
        case .restore, .delete: nil
        }
    }
}

/// Owns every comment mutation for the feature. All state changes flow through
/// here so the coordinator can enforce two ordering rules the design requires:
///   1. One mutation in flight per comment.
///   2. A change event emitted only after the server confirms the request.
/// Because every event describes committed server state, list fetches never
/// race an unconfirmed change and no settlement, generation, or reconcile
/// machinery is needed.
///
/// A genuine failure leaves the UI on the true pre-action state. The only
/// exceptions are three bounded failure mappings, where the desired outcome
/// holds anyway and the change is emitted: the same-status probe, already-
/// trashed, and 404.
///
/// Deliberately UI-free so it stays testable off the main-thread UI stack.
@MainActor
final class CommentsModerationCoordinator {
    /// Every committed change, in order. List view models apply each event;
    /// detail view models filter on their comment ID.
    let events = PassthroughSubject<CommentChangeEvent, Never>()

    private let service: any CommentsServiceProtocol
    private let tracker: (any CommentsTracker)?

    /// The in-flight mutation task per comment ID. Presence means "mutating";
    /// `waitForPendingMutation` awaits the stored task's value.
    private var inFlight: [Int64: Task<Void, Never>] = [:]

    init(service: any CommentsServiceProtocol, tracker: (any CommentsTracker)? = nil) {
        self.service = service
        self.tracker = tracker
    }

    func isMutating(id: Int64) -> Bool {
        inFlight[id] != nil
    }

    /// Awaits any in-flight mutation for the comment (re-entry race guard).
    func waitForPendingMutation(id: Int64) async {
        await inFlight[id]?.value
    }

    /// Broadcasts a status change the detail screen observed on load (its seed
    /// status disagreed with the fetched truth) without running a mutation, so
    /// loaded list tabs reconcile the corrected status in place.
    func noteExternalStatus(id: Int64, to: CommentListItem.Status) {
        events.send(.statusChanged(id: id, to: to))
    }

    /// Runs `action` pessimistically: the request is issued first and the change
    /// event is emitted only after it succeeds (or maps to a success). Throws
    /// the mutation error when the action genuinely failed, leaving the UI on
    /// the true pre-action state; the caller shows the error.
    func perform(_ action: CommentModerationAction, on comment: CommentDetail) async throws {
        guard !isMutating(id: comment.id) else { return } // one mutation per comment; UI already gates
        try await holdingSlot(for: comment.id) { [weak self] in
            guard let self else { throw CancellationError() }
            try await self.runModeration(action, on: comment)
        }
    }

    /// Runs `body` in an unstructured task that owns the comment's in-flight
    /// slot, so the mutation outlives a popped screen while the caller can
    /// still await its outcome. The slot claim happens synchronously before any
    /// suspension, so no second claimant can interleave.
    private func holdingSlot<T: Sendable>(
        for id: Int64,
        _ body: @escaping @MainActor () async throws -> T
    ) async throws -> T {
        let chain = Task { try await body() }
        let slot = Task { [weak self] in
            _ = try? await chain.value
            self?.inFlight[id] = nil
        }
        inFlight[id] = slot
        // Await the slot first so `isMutating` is false by the time the caller
        // resumes; the chain has already settled when the slot clears.
        await slot.value
        return try await chain.value
    }

    /// Runs one moderation request. The change event is emitted only after the
    /// server confirms, so every event describes committed state and list
    /// fetches never race an unconfirmed change.
    private func runModeration(_ action: CommentModerationAction, on comment: CommentDetail) async throws {
        do {
            let event = try await execute(action, id: comment.id)
            succeed(action, on: comment, event: event)
        } catch {
            try await mapFailure(error, action: action, on: comment)
        }
    }

    /// Issues the request for `action` and returns the change event describing
    /// the state the comment landed on.
    private func execute(_ action: CommentModerationAction, id: Int64) async throws -> CommentChangeEvent {
        switch action {
        case .approve:
            return .statusChanged(id: id, to: try await service.setStatus(id: id, .approved).status)
        case .unapprove:
            return .statusChanged(id: id, to: try await service.setStatus(id: id, .pending).status)
        case .spam:
            return .statusChanged(id: id, to: try await service.setStatus(id: id, .spam).status)
        case .trash:
            try await service.trash(id: id) // response carries no body
            return .statusChanged(id: id, to: .trash)
        case .restore:
            // Restore (unspam/untrash) is the only non-idempotent action. Core
            // restores in three steps: read the saved pre-bin status, reapply
            // it, then delete the saved value. So a second restore finds no
            // saved status, defaults to pending, and silently downgrades a
            // comment that had been restored to approved.
            //
            // Guard against that by probing the current status first:
            //   - Still .spam/.trash: genuinely in the bin, so restore it.
            //   - Any other status: it already left the bin (an earlier attempt
            //     landed, or another moderator moved it), so report that status
            //     and skip the corrupting second restore.
            // A failed probe throws and is handled as an ordinary failure, so no
            // restore runs on an unconfirmed state.
            let status = try await service.fetchStatus(id: id)
            guard status == .spam || status == .trash else { return .statusChanged(id: id, to: status) }
            // Restore from the probed bin, not the (possibly stale) status the
            // tap captured, so a comment another moderator moved between spam
            // and trash still runs the matching unspam/untrash hooks.
            //
            // Residual race (accepted): a restore can commit but lose its
            // response while PHP is still writing. An immediate retry would then
            // probe the still-pre-commit bin status, issue a second restore, and
            // hit the pending downgrade above. Why we accept it:
            //   1. The toolbar is disabled during a request, so a retry only
            //      follows a resolved error.
            //   2. If the first call did commit, losing its response means
            //      enough time passed that the fast untrash already landed, so
            //      the probe reads the active status and no second restore runs.
            //   3. If it genuinely failed, the probe reads the bin and the retry
            //      is safe.
            //   4. The gap only opens when a server-side untrash is slower than
            //      the client/proxy timeout (a pathological plugin hook); even
            //      then the downgrade is conservative and visible in Pending.
            // Closing it fully would need a restore-only recheck state (the
            // machinery this rewrite removed) or a server-side idempotent
            // restore.
            return .statusChanged(id: id, to: try await service.restore(id: id, from: status).status)
        case .delete:
            try await service.delete(id: id)
            return .deleted(id: id)
        }
    }

    /// Emits the single post-success event and fires the action's analytics
    /// event.
    private func succeed(_ action: CommentModerationAction, on comment: CommentDetail, event: CommentChangeEvent) {
        events.send(event)
        if let tracked = action.trackedEvent(commentID: comment.id, postID: comment.postID) {
            tracker?.track(tracked)
        }
    }

    /// Maps the failures whose desired outcome nevertheless holds; rethrows
    /// everything else as a genuine failure (the UI kept the pre-action state,
    /// so no correction is needed).
    ///
    /// It's possible that a request fails after the server already committed the
    /// change (client timeout, a proxy 502/504 while PHP finishes, a corrupted
    /// response body). The screen then shows the pre-action status alongside an
    /// error until the next fetch; a retry is confirmed by the same-status probe
    /// below. We consider that an edge case and accept the risk rather than
    /// refetching after every failure.
    private func mapFailure(
        _ error: Error,
        action: CommentModerationAction,
        on comment: CommentDetail
    ) async throws {
        let apiError = error as? WpApiError
        // Core returns 500 rest_comment_failed_edit when the requested status
        // equals the current one, i.e. the comment is already where the user
        // wants it (an earlier timed-out attempt landed, or another moderator
        // made the same change). One sparse status probe confirms; on match
        // this is a success, not a failure.
        if apiError?.wpErrorCode == .CommentFailedEdit,
            let actual = try? await service.fetchStatus(id: comment.id),
            probeConfirmsSuccess(action, actual: actual)
        {
            succeed(action, on: comment, event: .statusChanged(id: comment.id, to: actual))
            return
        }
        // Trash of an already-trashed comment: the goal state holds.
        if action == .trash, apiError?.wpErrorCode == .AlreadyTrashed {
            succeed(action, on: comment, event: .statusChanged(id: comment.id, to: .trash))
            return
        }
        // The comment is gone regardless of which action ran; remove it
        // everywhere. For delete that IS the goal; for anything else the action
        // still failed.
        if apiError?.httpStatusCode == 404 {
            events.send(.deleted(id: comment.id))
            if action == .delete { return }
        }
        throw error
    }

    /// Whether the probed status proves the action's goal holds. Any active
    /// status confirms a restore, because untrash/unspam reapply the saved
    /// pre-bin status (approved or pending).
    private func probeConfirmsSuccess(_ action: CommentModerationAction, actual: CommentListItem.Status) -> Bool {
        switch action {
        case .approve: actual == .approved
        case .unapprove: actual == .pending
        case .spam: actual == .spam
        case .trash: actual == .trash
        case .restore: actual == .approved || actual == .pending
        case .delete: false
        }
    }
}
