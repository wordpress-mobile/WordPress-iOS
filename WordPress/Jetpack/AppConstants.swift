import Foundation

@objc class AppConstants: NSObject {
    static let productTwitterHandle = "@jetpack"
    static let productTwitterURL = "https://twitter.com/jetpack"
    static let productBlogURL = "https://jetpack.com/blog"
    static let ticketSubject = "Jetpack for iOS Support"
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
}
