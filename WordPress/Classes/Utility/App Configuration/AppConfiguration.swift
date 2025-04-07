import Foundation
import BuildSettingsKit

/// - warning: Soft-deprecated. Use `BuildSettings` directly.
struct AppConfiguration {
    static var isJetpack: Bool {
        BuildSettings.current.brand == .jetpack
    }

    static var isWordPress: Bool {
        BuildSettings.current.brand == .wordpress
    }
}
