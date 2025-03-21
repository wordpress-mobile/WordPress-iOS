import Foundation
import BuildSettingsKit

@objc class AppConfiguration: NSObject {
    @objc static var isJetpack: Bool {
        BuildSettings.current.brand == .jetpack
    }

    @objc static var isWordPress: Bool {
        BuildSettings.current.brand == .wordpress
    }
}
