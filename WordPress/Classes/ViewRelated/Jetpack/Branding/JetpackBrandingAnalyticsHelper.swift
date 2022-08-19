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
        case activityLog
        case notifications
        case reader
        case readerSearch
        case stats
    }

    enum JetpackBadgeScreen: String {
        case activityDetail
        case appSettings
        case home
        case me
        case notificationsSettings
        case readerDetail
        case sharing
    }
}
