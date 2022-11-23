import Foundation

/// A class containing convenience methods for the the Jetpack features removal experience
class JetpackFeaturesRemovalCoordinator {

    /// Enum descibing the current phase of the Jetpack features removal
    enum GeneralPhase: String {
        case normal
        case one
        case two
        case three
        case four
        case newUsers

        var frequencyConfig: JetpackOverlayFrequencyTracker.FrequencyConfig {
            switch self {
            case .one:
                fallthrough
            case .two:
                return .init(featureSpecificInDays: 7, generalInDays: 2)
            case .three:
                return .init(featureSpecificInDays: 4, generalInDays: 1)
            default:
                return .defaultConfig
            }
        }
    }

    /// Enum descibing the current phase of the site creation flow removal
    enum SiteCreationPhase {
        case normal
        case one
        case two
    }

    enum OverlaySource: String {
        case stats
        case notifications
        case reader
        case card
        case login
        case appOpen = "app_open"
    }

    static func generalPhase(featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore()) -> GeneralPhase {
        if AppConfiguration.isJetpack {
            return .normal // Always return normal for Jetpack
        }

        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseNewUsers) {
            return .newUsers
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseFour) {
            return .four
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseThree) {
            return .three
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseTwo) {
            return .two
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseOne) {
            return .one
        }

        return .normal
    }

    static func siteCreationPhase(featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore()) -> SiteCreationPhase {
        if AppConfiguration.isJetpack {
            return .normal // Always return normal for Jetpack
        }

        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseNewUsers)
            || featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseFour) {
            return .two
        }
        if featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseThree)
            || featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseTwo)
            || featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseOne) {
            return .one
        }

        return .normal
    }

    /// Used to display feature-specific or feature-collection overlays.
    /// - Parameters:
    ///   - source: The source that triggers the display of the overlay.
    ///   - viewController: View controller where the overlay should be presented in.
    static func presentOverlayIfNeeded(from source: OverlaySource, in viewController: UIViewController) {
        let phase = generalPhase()
        let frequencyConfig = phase.frequencyConfig
        let viewModel = JetpackFullscreenOverlayGeneralViewModel(phase: phase, source: source)
        let frequencyTracker = JetpackOverlayFrequencyTracker(frequencyConfig: frequencyConfig, source: source)
        guard viewModel.shouldShowOverlay, frequencyTracker.shouldShow() else {
            return
        }
        createAndPresentOverlay(with: viewModel, in: viewController)
        frequencyTracker.track()
    }

    /// Used to display Site Creation overlays.
    /// - Parameters:
    ///   - viewController: View controller where the overlay should be presented in.
    static func presentSiteCreationOverlayIfNeeded(in viewController: UIViewController,
                                                   source: String,
                                                   onDismiss: JetpackOverlayDismissCallback? = nil) {
        let phase = siteCreationPhase()
        var viewModel = JetpackFullscreenOverlaySiteCreationViewModel(phase: phase, source: source)
        viewModel.onDismiss = onDismiss
        guard viewModel.shouldShowOverlay else {
            onDismiss?()
            return
        }
        createAndPresentOverlay(with: viewModel, in: viewController)
    }

    private static func createAndPresentOverlay(with viewModel: JetpackFullscreenOverlayViewModel, in viewController: UIViewController) {
        let overlay = JetpackFullscreenOverlayViewController(with: viewModel)
        let navigationViewController = UINavigationController(rootViewController: overlay)
        navigationViewController.modalPresentationStyle = .formSheet
        viewController.present(navigationViewController, animated: true)
    }
}
