import Foundation
import WordPressKit

/// - Warning:
/// This configuration class has a **Jetpack** counterpart in the Jetpack bundle.
/// Make sure to keep them in sync to avoid build errors when building the Jetpack target.
@objc class AppConstants: NSObject {
    static let mobileAnnounceAppId = "2"
    @objc static let authKeychainServiceName = "public-api.wordpress.com"
}
