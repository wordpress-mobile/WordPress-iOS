import Foundation
import WordPressData
import WordPressMediaLibrary
import WordPressShared

/// App-target adapter that bridges the module's `MediaTracker` to
/// `WPAppAnalytics` while preserving the V1 analytics property fidelity
/// (tap_source, tab_source) and adding an `is_v2: "1"` discriminator.
@MainActor
struct MediaTrackerAdapter: MediaTracker {
    let blog: Blog
    let baseProperties: [String: Any]

    func track(_ event: MediaTrackerEvent) {
        let stat: WPAnalyticsStat
        switch event {
        case .mediaLibraryOpened:
            stat = .openedMediaLibrary
        }
        WPAppAnalytics.track(stat, properties: baseProperties, blog: blog)
    }
}
