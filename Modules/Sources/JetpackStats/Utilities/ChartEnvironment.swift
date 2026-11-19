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
    /// Whether the view is redacted as a loading placeholder. Charts still draw every
    /// mark so the placeholder matches the loaded chart; they only skip animations and
    /// interaction.
    var isPlaceholder: Bool {
        redactionReasons.contains(.placeholder)
    }
}
