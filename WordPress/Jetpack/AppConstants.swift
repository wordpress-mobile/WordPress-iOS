import Foundation
import WordPressKit

@objc class AppConstants: NSObject {
    static let itunesAppID = "1565481562"
    static let productTwitterHandle = "@jetpack"
    static let productTwitterURL = "https://twitter.com/jetpack"
    static let productBlogURL = "https://jetpack.com/blog"
    static let productBlogDisplayURL = "jetpack.com/blog"
    static let zendeskSourcePlatform = "mobile_-_jp_ios"
    static let shareAppName: ShareAppName = .jetpack
    @objc static let eventNamePrefix = "jpios"

    /// Notifications Constants
    ///
    #if DEBUG
    static let pushNotificationAppId = "com.jetpack.appstore.dev"
    #else
    #if INTERNAL_BUILD
    static let pushNotificationAppId = "com.jetpack.internal"
    #else
    static let pushNotificationAppId = "com.jetpack.appstore"
    #endif
    #endif
}

// MARK: - Tab bar order
@objc enum WPTab: Int {
    case mySites
    case notifications
    // Reader on Jetpack is not displayed, but we keep it here to avoid adding conditionals on existing code
    case reader
}

// MARK: - Localized Strings
extension AppConstants {

    struct Settings {
        static let aboutTitle = NSLocalizedString("About Jetpack for iOS", comment: "Link to About screen for Jetpack for iOS")
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
}
