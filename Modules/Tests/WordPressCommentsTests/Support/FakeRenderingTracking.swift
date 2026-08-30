import UIKit
@testable import WordPressComments

@MainActor
final class FakeContentRenderer: NSObject, CommentContentRendering {
    let view = UIView()
    var onLinkTapped: ((URL) -> Void)?
    private(set) var renderedHTML: [String] = []

    func render(html: String) {
        renderedHTML.append(html)
    }
}

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
