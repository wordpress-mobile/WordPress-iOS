import Foundation
import WordPressShared

extension WPAnalytics {
    /// Fires the `screen_shown` event.
    static func track(
        screen: String,
        context: ScreenTrackingContext = ScreenTrackingContext(),
        properties: [String: String] = [:]
    ) {
        var props = context.properties
        props["screen"] = screen
        props.merge(properties) { _, new in new }
        WPAnalytics.track(.screenShown, properties: props)
    }
}

/// Describes the source screen and trigger that led to a navigation.
struct ScreenTrackingSource {
    /// The screen the user navigated from (e.g. `"reader.discover"`).
    let screen: String

    /// A sub-section within the screen (e.g. `"recommended"` for a Discover tab).
    var section: String?

    /// The UI element that triggered the navigation (e.g. `"post_card"`).
    var component: String?

    /// Position index for list items (0-based).
    var position: Int?

    init(_ screen: String, section: String? = nil, component: String? = nil, position: Int? = nil) {
        self.screen = screen
        self.section = section
        self.component = component
        self.position = position
    }
}

/// Describes how the user arrived at the current screen.
struct ScreenTrackingContext {
    var source: ScreenTrackingSource?

    /// Builds the properties dictionary for the analytics event.
    var properties: [String: String] {
        var props: [String: String] = [:]
        if let source {
            props["source"] = [source.screen, source.section, source.component]
                .compactMap { $0 }
                .joined(separator: ".")
            props["source_screen"] = source.screen
            if let section = source.section {
                props["source_section"] = section
            }
            if let component = source.component {
                props["source_component"] = component
                if let position = source.position {
                    props["source_component_position"] = String(position)
                }
            }
        }
        return props
    }
}
// MARK: - UIViewController

import UIKit

extension UIViewController {
    /// Tracking context describing how the user arrived at this screen.
    var trackingContext: ScreenTrackingContext {
        get { objc_getAssociatedObject(self, &AssociatedKeys.trackingContext) as? ScreenTrackingContext ?? ScreenTrackingContext() }
        set { objc_setAssociatedObject(self, &AssociatedKeys.trackingContext, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

private enum AssociatedKeys {
    static var trackingContext: UInt8 = 0
}

// MARK: - SwiftUI

import SwiftUI

private struct ScreenTrackingContextKey: EnvironmentKey {
    static let defaultValue = ScreenTrackingContext()
}

extension EnvironmentValues {
    var trackingContext: ScreenTrackingContext {
        get { self[ScreenTrackingContextKey.self] }
        set { self[ScreenTrackingContextKey.self] = newValue }
    }
}
