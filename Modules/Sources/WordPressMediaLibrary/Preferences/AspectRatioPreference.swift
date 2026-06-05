import Foundation
import UIKit
import WordPressShared

/// Read/write the V1 `mediaAspectRatioModeEnabled` UserDefaults key from
/// inside the module. The constant key lives in `WordPressShared`
/// (`UPRUConstants.mediaAspectRatioModeEnabledKey`); the convenience getter
/// the V1 host uses is on the app target's `UserPersistentRepositoryUtility`
/// extension, which the module can't reach — so we re-implement it locally.
/// Default matches V1: `.pad` users default to aspect-ratio mode on,
/// `.phone` to off.
enum AspectRatioPreference {
    private static let key = UPRUConstants.mediaAspectRatioModeEnabledKey

    static func load(defaults: UserDefaults = .standard) -> Bool {
        if let value = defaults.object(forKey: key) as? Bool { return value }
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    static func save(_ value: Bool, defaults: UserDefaults = .standard) {
        defaults.set(value, forKey: key)
    }
}
