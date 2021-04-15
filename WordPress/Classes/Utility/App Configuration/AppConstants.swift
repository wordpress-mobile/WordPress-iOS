import Foundation

struct AppConstants {
    static let productTwitterHandle = "@WordPressiOS"
    static let productTwitterURL = "https://twitter.com/WordPressiOS"
    static let productBlogURL = "https://blog.wordpress.com"

    static func jetpackSettingsURL(siteID: Int) -> URL? {
        return URL(string: "https://wordpress.com/settings/jetpack/\(siteID)")
    }
}

// MARK: - Localized Strings
extension AppConstants {

    struct Settings {
        static let aboutTitle = NSLocalizedString("About WordPress for iOS", comment: "Link to About screen for WordPress for iOS")
    }

}
