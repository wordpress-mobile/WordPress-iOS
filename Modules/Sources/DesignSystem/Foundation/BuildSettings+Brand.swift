import Foundation
import BuildSettingsKit

extension AppBrand {
    /// TODO: remove this when unit tests not longer rely on `BuildSettings.current`.
    static var current: AppBrand {
        if BuildSettingsEnvironment.current == .test {
            return .jetpack
        }
        return BuildSettings.current.brand
    }
}
