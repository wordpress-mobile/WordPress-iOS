import Foundation

/**
 * Jetpack Configuration
 * - Warning:
 * This configuration class has a **WordPress** counterpart in the WordPress bundle.
 * Make sure to keep them in sync to avoid build errors when building the WordPress target.
 */
@objc class AppConfiguration: NSObject {
    @objc static let isJetpack: Bool = true
    @objc static let isWordPress: Bool = false
}
