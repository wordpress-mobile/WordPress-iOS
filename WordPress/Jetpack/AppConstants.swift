import Foundation
import WordPressKit

/// - Warning:
/// This configuration class has a **WordPress** counterpart in the WordPress bundle.
/// Make sure to keep them in sync to avoid build errors when building the WordPress target.
@objc class AppConstants: NSObject {
    static let shareAppName: ShareAppName = .jetpack
    static let mobileAnnounceAppId = "6"
    @objc static let authKeychainServiceName = "jetpack.public-api.wordpress.com"
}
