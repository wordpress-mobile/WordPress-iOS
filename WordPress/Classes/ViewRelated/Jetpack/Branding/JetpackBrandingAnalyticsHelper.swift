import Foundation
import AutomatticTracks

struct JetpackBrandingAnalyticsHelper {
    private static let screenPropertyKey = "screen"

    // MARK: - Jetpack powered badge tapped
    static func trackJetpackPoweredBadgeTapped(screen: JetpackBadgeScreen) {
        let properties = [screenPropertyKey: screen.rawValue]
        WPAnalytics.track(.jetpackPoweredBadgeTapped, properties: properties)
    }

    // MARK: - Jetpack powered banner tapped
    static func trackJetpackPoweredBannerTapped(screen: JetpackBannerScreen) {
        let properties = [screenPropertyKey: screen.rawValue]
        WPAnalytics.track(.jetpackPoweredBannerTapped, properties: properties)
    }

    // MARK: - Jetpack powered bottom sheet button tapped
    static func trackJetpackPoweredBottomSheetButtonTapped() {
        WPAnalytics.track(.jetpackPoweredBottomSheetButtonTapped)
    }
}
