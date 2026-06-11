import Foundation
import WordPressData
import WordPressMediaLibrary
import WordPressShared

/// App-target adapter that bridges the module's `MediaTracker` to
/// `WPAppAnalytics` while preserving V1 analytics property fidelity
/// (`tap_source`, `tab_source`, `is_v2`).
@MainActor
struct MediaTrackerAdapter: MediaTracker {
    let blog: Blog
    let baseProperties: [String: Any]

    func track(_ event: MediaTrackerEvent) {
        let stat: WPAnalyticsStat
        var properties = baseProperties

        switch event {
        case .mediaLibraryOpened:
            stat = .openedMediaLibrary

        case .mediaLibraryFilterChanged(let kind):
            stat = .siteMediaFilterChanged
            properties["filter_kind"] = kind?.rawValue ?? "all"

        case .mediaLibrarySearched(let queryLength):
            stat = .siteMediaSearched
            properties["query_length"] = queryLength

        case .mediaLibraryGridModeToggled(let isAspectRatio):
            stat = .siteMediaGridModeToggled
            properties["mode"] = isAspectRatio ? "aspect_ratio" : "square"
        }

        WPAppAnalytics.track(stat, properties: properties, blog: blog)
    }
}
