
import Foundation

/// An enum that unifies the checks to limit the visibility of the Jetpack branding elements (banners and badges)
enum JetpackBrandingVisibility {

    case all
    case featureFlagBased

    var enabled: Bool {
        switch self {
        case .all:
            return AppConfiguration.isWordPress &&
            AccountHelper.isDotcomAvailable() &&
            JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures()
        case .featureFlagBased:
            return true
        }
    }
}
