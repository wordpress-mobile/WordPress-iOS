import Foundation
import AutomatticTracks

struct JetpackBrandingAnalyticsHelper {
    private static let screenPropertyKey = "screen"

    // MARK: - Jetpack powered badge tapped
    static func trackJetpackPoweredBadgeTapped(screen: Self.JetpackBadgeScreen) {
        let properties = [screenPropertyKey: screen.rawValue]
        WPAnalytics.track(.jetpackPoweredBadgeTapped, properties: properties)
    }

    // MARK: - Jetpack powered banner tapped
    static func trackJetpackPoweredBannerTapped(screen: Self.JetpackBannerScreen) {
        let properties = [screenPropertyKey: screen.rawValue]
        WPAnalytics.track(.jetpackPoweredBannerTapped, properties: properties)
    }

    // MARK: - Jetpack powered bottom sheet button tapped
    static func trackJetpackPoweredBottomSheetButtonTapped() {
        WPAnalytics.track(.jetpackPoweredBottomSheetButtonTapped)
    }

    enum JetpackBannerScreen: String {
        case activityLog = "activity_log"
        case backup
        case menus
        case notifications
        case people
        case reader
        case readerSearch = "reader_search"
        case stats
        case themes
    }

    enum JetpackBadgeScreen: String {
        case activityDetail = "activity_detail"
        case appSettings = "app_settings"
        case home
        case me
        case notificationsSettings = "notifications_settings"
        case person
        case readerDetail = "reader_detail"
        case sharing
    }
}
