import Foundation

protocol JetpackBrandedScreen {
    var featureName: String? { get }
    var isPlural: Bool { get }
    var analyticsId: String { get }
}

enum JetpackBannerScreen: String, JetpackBrandedScreen {
    case activityLog = "activity_log"
    case backup
    case notifications
    case people
    case reader
    case readerSearch = "reader_search"
    case stats

    var featureName: String? {
        switch self {
        case .activityLog:
            return NSLocalizedString("Activity", comment: "Noun. Name of the Activity Log feature")
        case .backup:
            return NSLocalizedString("Backup", comment: "Noun. Name of the Backup feature")
        case .notifications:
            return NSLocalizedString("Notifications", comment: "Noun. Name of the Notifications feature")
        case .people:
            return NSLocalizedString("People Management", comment: "Noun. Name of the People feature")
        case .reader:
            return NSLocalizedString("Reader", comment: "Noun. Name of the Reader feature")
        case .readerSearch:
            return NSLocalizedString("Reader", comment: "Noun. Name of the Reader feature")
        case .stats:
            return NSLocalizedString("Stats", comment: "Noun. Abbreviation of Statistics. Name of the Stats feature")
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
        case .readerSearch:
            return false
        case .notifications:
            fallthrough
        case .stats:
            return true
        }
    }

    var analyticsId: String {
        rawValue
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
        case .me:
            return nil
        case .activityDetail:
            return NSLocalizedString("Activity", comment: "Noun. Name of the Activity Log feature")
        case .notificationsSettings:
            return NSLocalizedString("Notifications", comment: "Noun. Name of the Notifications feature")
        case .person:
            return NSLocalizedString("People Management", comment: "Noun. Name of the People feature")
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

    var analyticsId: String {
        rawValue
    }
}
