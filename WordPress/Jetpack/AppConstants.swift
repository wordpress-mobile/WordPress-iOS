import Foundation
import WordPressKit

/// - Warning:
/// This configuration class has a **WordPress** counterpart in the WordPress bundle.
/// Make sure to keep them in sync to avoid build errors when building the WordPress target.
@objc class AppConstants: NSObject {
    static let productTwitterHandle = "@jetpack"
    static let productTwitterURL = "https://twitter.com/jetpack"
    static let productBlogURL = "https://jetpack.com/blog"
    static let productBlogDisplayURL = "jetpack.com/blog"
    static let zendeskSourcePlatform = "mobile_-_jp_ios"
    static let shareAppName: ShareAppName = .jetpack
    static let mobileAnnounceAppId = "6"
    @objc static let authKeychainServiceName = "jetpack.public-api.wordpress.com"
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

    struct Settings {
        static let aboutTitle = NSLocalizedString("About Jetpack for iOS", comment: "Link to About screen for Jetpack for iOS")
        static let shareButtonTitle = NSLocalizedString("Share Jetpack with a friend", comment: "Title for a button that recommends the app to others")
        static let whatIsNewTitle = NSLocalizedString("What's New in Jetpack", comment: "Opens the What's New / Feature Announcement modal")
    }

    struct Logout {
        static let alertTitle = NSLocalizedString("Log out of Jetpack?", comment: "LogOut confirmation text, whenever there are no local changes")
    }

    struct Zendesk {
        static let ticketSubject = NSLocalizedString("Jetpack for iOS Support", comment: "Subject of new Zendesk ticket.")
    }
}
