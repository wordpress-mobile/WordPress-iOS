import Foundation

/**
 * WordPress Configuration
 * - Warning:
 * This configuration class has a **Jetpack** counterpart in the Jetpack bundle.
 * Make sure to keep them in sync to avoid build errors when building the Jetpack target.
 */
@objc class AppConfiguration: NSObject {
    @objc static let isJetpack: Bool = false
    @objc static let isWordPress: Bool = true
}
