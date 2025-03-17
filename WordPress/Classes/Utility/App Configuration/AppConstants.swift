import Foundation
import WordPressKit

/// - Warning:
/// This configuration class has a **Jetpack** counterpart in the Jetpack bundle.
/// Make sure to keep them in sync to avoid build errors when building the Jetpack target.
@objc class AppConstants: NSObject {
    static let itunesAppID = "335703880"
    static let productTwitterHandle = "@WordPressiOS"
    static let productTwitterURL = "https://twitter.com/WordPressiOS"
    static let productBlogURL = "https://wordpress.org/news/"
    static let productBlogDisplayURL = "wordpress.org/news"
    static let zendeskSourcePlatform = "mobile_-_ios"
    static let shareAppName: ShareAppName = .wordpress
    static let mobileAnnounceAppId = "2"
    @objc static let eventNamePrefix = "wpios"
    @objc static let explatPlatform = "wpios"
    @objc static let authKeychainServiceName = "public-api.wordpress.com"
}

// MARK: - Localized Strings
extension AppConstants {

    struct AboutScreen {
        static let blogName = NSLocalizedString("News", comment: "Title of a button that displays the WordPress.org blog")
        static let workWithUs = NSLocalizedString("Contribute", comment: "Title of button that displays the WordPress.org contributor page")
        static let workWithUsURL = "https://make.wordpress.org/mobile/handbook"
    }

    struct AppRatings {
        static let prompt = NSLocalizedString("appRatings.wordpress.prompt", value: "What do you think about WordPress?", comment: "This is the string we display when prompting the user to review the WordPress app")
    }

    struct Settings {
        static let aboutTitle: String = NSLocalizedString("About WordPress", comment: "Link to About screen for WordPress for iOS")
        static let shareButtonTitle = NSLocalizedString("Share WordPress with a friend", comment: "Title for a button that recommends the app to others")
        static let whatIsNewTitle = NSLocalizedString("What's New in WordPress", comment: "Opens the What's New / Feature Announcement modal")
    }

    struct Logout {
        static let alertTitle = NSLocalizedString("Log out of WordPress?", comment: "LogOut confirmation text, whenever there are no local changes")
    }

    struct Zendesk {
        static let ticketSubject = NSLocalizedString("WordPress for iOS Support", comment: "Subject of new Zendesk ticket.")
    }
}
