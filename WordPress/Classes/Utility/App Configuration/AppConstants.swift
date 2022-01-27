import Foundation
import WordPressAuthenticator

@objc class AppConstants: NSObject {
    static let itunesAppID = "335703880"
    static let productTwitterHandle = "@WordPressiOS"
    static let productTwitterURL = "https://twitter.com/WordPressiOS"
    static let productBlogURL = "https://blog.wordpress.com"
    static let productBlogDisplayURL = "blog.wordpress.com"
    static let zendeskSourcePlatform = "mobile_-_ios"
    static let shareAppName: ShareAppName = .wordpress
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

// MARK: - Tab bar order
@objc enum WPTab: Int {
    case mySites
    case reader
    case notifications
}

// MARK: - Localized Strings
extension AppConstants {

    struct Settings {
        static let aboutTitle: String = {
            if FeatureFlag.aboutScreen.enabled {
                return NSLocalizedString("About WordPress", comment: "Link to About screen for WordPress for iOS")
            } else {
                return NSLocalizedString("About WordPress for iOS", comment: "Link to About screen for WordPress for iOS")
            }
        }()
    }

    struct Login {
        static let continueButtonTitle = WordPressAuthenticatorDisplayStrings.defaultStrings.continueWithWPButtonTitle
    }

    struct Logout {
        static let alertTitle = NSLocalizedString("Log out of WordPress?", comment: "LogOut confirmation text, whenever there are no local changes")
    }

    struct Zendesk {
        static let ticketSubject = NSLocalizedString("WordPress for iOS Support", comment: "Subject of new Zendesk ticket.")
    }
}
