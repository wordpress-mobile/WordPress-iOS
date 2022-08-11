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

    struct PostSignUpInterstitial {
        static let welcomeTitleText = NSLocalizedString("Welcome to WordPress", comment: "Post Signup Interstitial Title Text for WordPress iOS")
    }

    struct Settings {
        static let aboutTitle: String = NSLocalizedString("About WordPress", comment: "Link to About screen for WordPress for iOS")
        static let shareButtonTitle = NSLocalizedString("Share WordPress with a friend", comment: "Title for a button that recommends the app to others")
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

    struct QuickStart {
        static let getToKnowTheAppTourTitle = NSLocalizedString("Get to know the WordPress app",
                                                                comment: "Name of the Quick Start list that guides users through a few tasks to explore the WordPress app.")
    }
}
