import Foundation
import BuildSettingsKit

extension AppBrand {
    static var current: AppBrand {
        // TODO: remove this when unit tests not longer rely on `BuildSettings.current`.
        if BuildSettingsEnvironment.current == .test {
            return .jetpack
        }
        return BuildSettings.current.brand
    }
}
