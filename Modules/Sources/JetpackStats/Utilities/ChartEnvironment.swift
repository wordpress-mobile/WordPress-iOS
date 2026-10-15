import SwiftUI

private struct ShowComparisonKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var showComparison: Bool {
        get { self[ShowComparisonKey.self] }
        set { self[ShowComparisonKey.self] = newValue }
    }
}

extension EnvironmentValues {
    /// Whether the view is redacted as a loading placeholder. Charts use it to skip
    /// effects that are invisible at placeholder opacity.
    var isPlaceholder: Bool {
        redactionReasons.contains(.placeholder)
    }
}
