import Combine
import Foundation
@testable import WordPressComments

/// Records every event the coordinator publishes, in order.
@MainActor
final class EventRecorder {
    private(set) var events: [CommentChangeEvent] = []
    private var subscription: AnyCancellable?

    init(_ coordinator: CommentsModerationCoordinator) {
        subscription = coordinator.events.sink { [weak self] in self?.events.append($0) }
    }
}

/// Polls until `condition` holds or a generous bound is reached, letting a
/// detached task (a view model's `perform`, a coordinator chain) run up to
/// the point the test wants to observe. Bounded so a regression fails the
/// test instead of hanging the suite.
@MainActor
func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<1000 {
        if condition() { return }
        await Task.yield()
    }
}
