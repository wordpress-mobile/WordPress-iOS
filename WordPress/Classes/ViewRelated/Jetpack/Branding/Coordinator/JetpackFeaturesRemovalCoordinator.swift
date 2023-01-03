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
    enum SiteCreationPhase: String {
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

        /// Used to differentiate between last saved dates for different phases.
        /// Should return a dynamic value if each phase should be treated differently.
        /// Should return nil if all phases should be treated the same.
        func frequencyTrackerPhaseString(phase: GeneralPhase) -> String? {
            switch self {
            case .login:
                fallthrough
            case .appOpen:
                return phase.rawValue // Shown once per phase
            default:
                return nil // Phase is irrelevant.
            }
        }
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

    static func removalDeadline(remoteConfigStore: RemoteConfigStore = RemoteConfigStore()) -> Date? {
        guard let dateString = RemoteConfig(store: remoteConfigStore).jetpackDeadline.value else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    /// Used to determine if the Jetpack features are enabled based on the removal phase.
    static func jetpackFeaturesEnabled() -> Bool {
        switch generalPhase() {
        case .four, .newUsers:
            return false
        default:
            return true
        }
    }

    /// Used to display feature-specific or feature-collection overlays.
    /// - Parameters:
    ///   - source: The source that triggers the display of the overlay.
    ///   - viewController: View controller where the overlay should be presented in.
    static func presentOverlayIfNeeded(from source: OverlaySource, in viewController: UIViewController) {
        let phase = generalPhase()
        let frequencyConfig = phase.frequencyConfig
        let frequencyTrackerPhaseString = source.frequencyTrackerPhaseString(phase: phase)
        let viewModel = JetpackFullscreenOverlayGeneralViewModel(phase: phase, source: source)
        let frequencyTracker = JetpackOverlayFrequencyTracker(frequencyConfig: frequencyConfig,
                                                              phaseString: frequencyTrackerPhaseString,
                                                              source: source)
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
