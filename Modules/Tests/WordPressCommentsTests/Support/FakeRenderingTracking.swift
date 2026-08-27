import UIKit
@testable import WordPressComments

// `CommentsTracker` is non-isolated, so this spy can't be `@MainActor` like the
// other fakes. `NSLock` enforces (rather than just documents) that concurrent
// `track(_:)` writes and `trackedEvents` reads are race-free.
final class SpyCommentsTracker: CommentsTracker, @unchecked Sendable {
    private let lock = NSLock()
    private var events: [CommentsTrackedEvent] = []

    var trackedEvents: [CommentsTrackedEvent] {
        lock.withLock { events }
    }

    func track(_ event: CommentsTrackedEvent) {
        lock.withLock { events.append(event) }
    }
}
