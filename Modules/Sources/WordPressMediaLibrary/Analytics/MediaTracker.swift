import Foundation

/// Analytics protocol for the Media Library module.
///
/// `@MainActor` rather than `Sendable` because the app-target adapter stores
/// `Blog` (an `NSManagedObject`, not Sendable) and a properties dictionary
/// containing `Any`. The open event always fires from a MainActor context
/// (`MediaLibraryView.task`), so MainActor isolation is the right shape.
@MainActor
public protocol MediaTracker {
    func track(_ event: MediaTrackerEvent)
}

public enum MediaTrackerEvent: Sendable {
    case mediaLibraryOpened
    case mediaLibraryFilterChanged(kind: MediaKind?) // nil = "All"
    case mediaLibrarySearched(queryLength: Int) // fires AFTER 300ms debounce trailing edge; non-empty only
    case mediaLibraryGridModeToggled(isAspectRatio: Bool)
}

/// No-op tracker for previews and module-internal default-construction.
@MainActor
public struct MockMediaTracker: MediaTracker {
    public init() {}

    public func track(_ event: MediaTrackerEvent) {
        #if DEBUG
        debugPrint("[MediaTracker] \(event)")
        #endif
    }
}
