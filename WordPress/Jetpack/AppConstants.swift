import Foundation
import WordPressKit

/// - Warning:
/// This configuration class has a **WordPress** counterpart in the WordPress bundle.
/// Make sure to keep them in sync to avoid build errors when building the WordPress target.
@objc class AppConstants: NSObject {
    static let itunesAppID = "1565481562"
    static let productTwitterHandle = "@jetpack"
    static let productTwitterURL = "https://twitter.com/jetpack"
    static let productBlogURL = "https://jetpack.com/blog"
    static let productBlogDisplayURL = "jetpack.com/blog"
    static let zendeskSourcePlatform = "mobile_-_jp_ios"
    static let shareAppName: ShareAppName = .jetpack
    static let mobileAnnounceAppId = "6"
    @objc static let eventNamePrefix = "jpios"
    @objc static let explatPlatform = "wpios"
    @objc static let authKeychainServiceName = "jetpack.public-api.wordpress.com"

    /// Notifications Constants
    ///
    #if DEBUG
    static let pushNotificationAppId = "com.jetpack.appstore.dev"
    #else
    #if INTERNAL_BUILD
    static let pushNotificationAppId = "com.jetpack.internal"
    #else
    #if ALPHA_BUILD
    static let pushNotificationAppId = "com.jetpack.alpha"
    #else
    static let pushNotificationAppId = "com.jetpack.appstore"
    #endif
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

    struct AboutScreen {
        static let blogName = NSLocalizedString("Blog", comment: "Title of a button that displays the WordPress.com blog")
        static let workWithUs = NSLocalizedString("Work With Us", comment: "Title of button that displays the Automattic Work With Us web page")
        static let workWithUsURL = "https://automattic.com/work-with-us"
    }

    struct AppRatings {
        static let prompt = NSLocalizedString("appRatings.jetpack.prompt", value: "What do you think about Jetpack?", comment: "This is the string we display when prompting the user to review the Jetpack app")
    }

    struct PostSignUpInterstitial {
        static let welcomeTitleText = NSLocalizedString("Welcome to Jetpack", comment: "Post Signup Interstitial Title Text for Jetpack iOS")
    }

    struct Settings {
        static let aboutTitle = NSLocalizedString("About Jetpack for iOS", comment: "Link to About screen for Jetpack for iOS")
        static let shareButtonTitle = NSLocalizedString("Share Jetpack with a friend", comment: "Title for a button that recommends the app to others")
        static let whatIsNewTitle = NSLocalizedString("What's New in Jetpack", comment: "Opens the What's New / Feature Announcement modal")
    }

    struct Login {
        static let continueButtonTitle = NSLocalizedString(
            "Continue With WordPress.com",
            comment: "Button title. Takes the user to the login with WordPress.com flow."
        )
    }

    struct Logout {
        static let alertTitle = NSLocalizedString("Log out of Jetpack?", comment: "LogOut confirmation text, whenever there are no local changes")
    }

    struct Zendesk {
        static let ticketSubject = NSLocalizedString("Jetpack for iOS Support", comment: "Subject of new Zendesk ticket.")
    }

    struct QuickStart {
        static let getToKnowTheAppTourTitle = NSLocalizedString("Get to know the Jetpack app",
                                                                comment: "Name of the Quick Start list that guides users through a few tasks to explore the Jetpack app.")
    }
}
