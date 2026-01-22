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
