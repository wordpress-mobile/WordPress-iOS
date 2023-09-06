
import Foundation

/// An enum that unifies the checks to limit the visibility of the Jetpack branding elements (banners and badges)
enum JetpackBrandingVisibility {

    case all
    case wordPressApp
    case dotcomAccounts
    case dotcomAccountsOnWpApp // useful if we want to release in phases and exclude the feature flag in some cases
    case featureFlagBased

    var enabled: Bool {
        switch self {
        case .all:
            return AppConfiguration.isWordPress &&
            AccountHelper.isDotcomAvailable() &&
            JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures()
        case .wordPressApp:
            return AppConfiguration.isWordPress
        case .dotcomAccounts:
            return AccountHelper.isDotcomAvailable()
        case .dotcomAccountsOnWpApp:
            return AppConfiguration.isWordPress &&
            AccountHelper.isDotcomAvailable()
        case .featureFlagBased:
            return true
        }
    }
}
