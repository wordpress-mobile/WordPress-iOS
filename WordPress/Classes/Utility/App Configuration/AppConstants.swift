import Foundation
import WordPressAuthenticator

@objc class AppConstants: NSObject {
    static let productTwitterHandle = "@WordPressiOS"
    static let productTwitterURL = "https://twitter.com/WordPressiOS"
    static let productBlogURL = "https://blog.wordpress.com"
    static let ticketSubject = NSLocalizedString("WordPress for iOS Support", comment: "Subject of new Zendesk ticket.")
    @objc static let eventNamePrefix = "wpios"

    /// Notifications Constants
    ///
    #if DEBUG
    static let pushNotificationAppId = "org.wordpress.appstore.dev"
    #else
    #if INTERNAL_BUILD
    static let pushNotificationAppId = "org.wordpress.internal"
    #else
    static let pushNotificationAppId = "org.wordpress.appstore"
    #endif
    #endif
}

// MARK: - Localized Strings
extension AppConstants {

    struct Settings {
        static let aboutTitle = NSLocalizedString("About WordPress for iOS", comment: "Link to About screen for WordPress for iOS")
    }

    struct Login {
        static let continueButtonTitle = WordPressAuthenticatorDisplayStrings.defaultStrings.continueWithWPButtonTitle
    }
}
