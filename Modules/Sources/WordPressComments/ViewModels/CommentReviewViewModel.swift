import Combine
import Foundation
import WordPressShared

/// One pass through a copied list. Entry IDs bind delayed loads and controls to
/// their original comment; coordinator results alone can earn moderation credit.
@MainActor
final class CommentReviewViewModel: ObservableObject, Identifiable {
    enum Outcome {
        case moderated
        case skipped
        case bypassed
    }

    let batch: [CommentListItem]
    @Published private(set) var detail: CommentDetailViewModel?
    @Published private(set) var position = 0
    @Published private(set) var outcomes: [Int64: Outcome] = [:]
    @Published private(set) var pendingAction: CommentModerationAction?
    @Published private(set) var isDismissed = false

    var isComplete: Bool { !isDismissed && position == batch.count }
    var moderatedCount: Int { outcomes.values.filter { $0 == .moderated }.count }
    var skippedCount: Int { outcomes.values.filter { $0 == .skipped }.count }
    var canSkip: Bool { !isDismissed && detail != nil && pendingAction == nil }
    /// Reads the current detail's state live; views that render this must
    /// observe that detail as well as the session.
    var canModerate: Bool { canSkip && detail?.isToolbarEnabled == true && detail?.loadedDetail?.status == .pending }

    private let coordinator: CommentsModerationCoordinator
    private let noticePresenter: any NoticePresenting
    private let makeDetail: (CommentListItem) -> CommentDetailViewModel
    private var subscription: AnyCancellable?
    private var knownNonpending: Set<Int64> = []

    init(
        batch: [CommentListItem],
        coordinator: CommentsModerationCoordinator,
        noticePresenter: any NoticePresenting,
        makeDetail: @escaping (CommentListItem) -> CommentDetailViewModel
    ) {
        // Unique IDs let a live `detail` for an ID imply it has no outcome yet.
        self.batch = batch.deduplicated(by: \.id)
        self.coordinator = coordinator
        self.noticePresenter = noticePresenter
        self.makeDetail = makeDetail
        subscription = coordinator.events.sink { [weak self] in self?.handle($0) }
        showCurrent()
    }

    func loadCurrent(id: Int64, retry: Bool = false) async {
        guard !isDismissed, let detail, detail.commentID == id else { return }
        if retry {
            await detail.retry()
        } else {
            await detail.onAppear()
        }
        guard !isDismissed, self.detail === detail, pendingAction == nil else { return }
        if detail.isMissing {
            coordinator.events.send(.deleted(id: id))
        } else if let loaded = detail.loadedDetail, loaded.status != .pending {
            record(.bypassed, id: id)
        }
    }

    func skip(id: Int64) {
        guard canSkip, detail?.commentID == id else { return }
        record(.skipped, id: id)
    }

    func close() {
        isDismissed = true
        subscription = nil
        detail = nil
    }

    func perform(_ action: CommentModerationAction, id: Int64) {
        guard canModerate, let detail, detail.commentID == id, let loaded = detail.loadedDetail else { return }
        pendingAction = action
        // This task survives Close. The presenter and coordinator remain alive
        // even if the session is released while its request is running.
        Task { [coordinator, noticePresenter, weak self] in
            var landed: CommentListItem.Status?
            var failed = false
            do {
                if case .statusChanged(_, let status) = try await coordinator.perform(action, on: loaded) {
                    landed = status
                }
            } catch {
                failed = true
            }
            if failed || landed == .pending {
                noticePresenter.present(title: Strings.moderationFailed)
            }
            guard let self, !self.isDismissed, self.detail === detail else { return }
            self.pendingAction = nil
            if let landed, action.isConfirmed(by: landed) {
                self.record(.moderated, id: id)
            } else if self.knownNonpending.contains(id) {
                self.record(.bypassed, id: id)
            }
        }
    }

    private func handle(_ event: CommentChangeEvent) {
        guard !isDismissed, outcomes[event.commentID] == nil else { return }
        switch event {
        case .deleted:
            knownNonpending.insert(event.commentID)
        case .statusChanged(_, let status):
            if status == .pending {
                knownNonpending.remove(event.commentID)
            } else {
                knownNonpending.insert(event.commentID)
            }
        case .contentChanged, .replyCreated:
            return
        }
        // Our own operation emits before returning. Settle its response and
        // events together, so an event cannot advance before credit is known.
        if detail?.commentID == event.commentID, pendingAction == nil, knownNonpending.contains(event.commentID) {
            record(.bypassed, id: event.commentID)
        }
    }

    private func record(_ outcome: Outcome, id: Int64) {
        guard !isDismissed, detail?.commentID == id else { return }
        outcomes[id] = outcome
        position += 1
        showCurrent()
    }

    private func showCurrent() {
        while position < batch.count, knownNonpending.contains(batch[position].id) {
            outcomes[batch[position].id] = .bypassed
            position += 1
        }
        detail = position < batch.count ? makeDetail(batch[position]) : nil
    }
}
