import Foundation

protocol JetpackBrandedScreen {

    /// Name to use when constructing phase three branding text.
    /// Set to `nil` to fallback to the default branding text.
    var featureName: String? { get }

    /// Whether the feature is in plural form.
    /// Used to decide on using "is" or "are" when constructing the branding text.
    var isPlural: Bool { get }
}

enum JetpackBannerScreen: String, JetpackBrandedScreen {
    case activityLog = "activity_log"
    case backup
    case menus
    case notifications
    case people
    case reader
    case readerSearch = "reader_search"
    case scan
    case stats
    case themes

    var featureName: String? {
        switch self {
        case .activityLog:
            return NSLocalizedString("Activity", comment: "Noun. Name of the Activity Log feature")
        case .backup:
            return NSLocalizedString("Backup", comment: "Noun. Name of the Backup feature")
        case .menus:
            return NSLocalizedString("Menus", comment: "Noun. Name of the Menus feature")
        case .notifications:
            return NSLocalizedString("Notifications", comment: "Noun. Name of the Notifications feature")
        case .people:
            return nil
        case .reader:
            return NSLocalizedString("Reader", comment: "Noun. Name of the Reader feature")
        case .readerSearch:
            return NSLocalizedString("Reader", comment: "Noun. Name of the Reader feature")
        case .scan:
            return NSLocalizedString("Scan", comment: "Noun. Name of the Scan feature")
        case .stats:
            return NSLocalizedString("Stats", comment: "Noun. Abbreviation of Statistics. Name of the Stats feature")
        case .themes:
            return NSLocalizedString("Themes", comment: "Noun. Name of the Themes feature")
        }
    }

    var isPlural: Bool {
        switch self {
        case .activityLog:
            fallthrough
        case .backup:
            fallthrough
        case .reader:
            fallthrough
        case .people:
            fallthrough
        case .scan:
            fallthrough
        case .readerSearch:
            return false
        case .notifications:
            fallthrough
        case .menus:
            fallthrough
        case .themes:
            fallthrough
        case .stats:
            return true
        }
    }
}

enum JetpackBadgeScreen: String, JetpackBrandedScreen {
    case activityDetail = "activity_detail"
    case appSettings = "app_settings"
    case home
    case me
    case notificationsSettings = "notifications_settings"
    case person
    case readerDetail = "reader_detail"
    case sharing

    var featureName: String? {
        switch self {
        case .appSettings:
            fallthrough
        case .home:
            fallthrough
        case .person:
            fallthrough
        case .me:
            return nil
        case .activityDetail:
            return NSLocalizedString("Activity", comment: "Noun. Name of the Activity Log feature")
        case .notificationsSettings:
            return NSLocalizedString("Notifications", comment: "Noun. Name of the Notifications feature")
        case .readerDetail:
            return NSLocalizedString("Reader", comment: "Noun. Name of the Reader feature")
        case .sharing:
            return NSLocalizedString("Sharing", comment: "Noun. Name of the Social Sharing feature")
        }

    }

    var isPlural: Bool {
        switch self {
        case .appSettings:
            fallthrough
        case .home:
            fallthrough
        case .me:
            fallthrough
        case .activityDetail:
            fallthrough
        case .readerDetail:
            fallthrough
        case .person:
            fallthrough
        case .sharing:
            return false
        case .notificationsSettings:
            return true
        }
    }
}
