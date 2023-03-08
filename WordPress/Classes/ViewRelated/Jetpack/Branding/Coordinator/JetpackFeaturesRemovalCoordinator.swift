import Foundation

/// A class containing convenience methods for the the Jetpack features removal experience
class JetpackFeaturesRemovalCoordinator: NSObject {

    /// Enum describing the current phase of the Jetpack features removal
    enum GeneralPhase: String {
        case normal
        case one
        case two
        case three
        case four
        case newUsers = "new_users"
        case selfHosted = "self_hosted"

        var frequencyConfig: OverlayFrequencyTracker.FrequencyConfig {
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

    /// Enum describing the current phase of the site creation flow removal
    enum SiteCreationPhase: String {
        case normal
        case one
        case two
    }

    enum JetpackOverlaySource: String, OverlaySource {
        case stats
        case notifications
        case reader
        case card
        case login
        case appOpen = "app_open"
        case disabledEntryPoint = "disabled_entry_point"

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

        var key: String {
            return rawValue
        }

        var frequencyType: OverlayFrequencyTracker.FrequencyType {
            switch self {
            case .stats:
                fallthrough
            case .notifications:
                fallthrough
            case .reader:
                return .respectFrequencyConfig
            case .card:
                fallthrough
            case .disabledEntryPoint:
                return .alwaysShow
            case .login:
                fallthrough
            case .appOpen:
                return .showOnce
            }
        }
    }

    static func generalPhase(featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore()) -> GeneralPhase {
        if AppConfiguration.isJetpack {
            return .normal // Always return normal for Jetpack
        }


        if AccountHelper.noWordPressDotComAccount {
            let selfHostedRemoval = featureFlagStore.value(for: FeatureFlag.jetpackFeaturesRemovalPhaseSelfHosted)
            return selfHostedRemoval ? .selfHosted : .normal
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

    /// Used to determine if the Jetpack features are enabled based on the current app UI type.
    /// This way we ensure features are not removed before reloading the UI.
    /// But if this function is called from a background thread, we determine if the Jetpack Features
    /// are enabled based on the removal phase regardless of the app UI state.
    /// Default root view coordinator is used.
    @objc
    static func jetpackFeaturesEnabled() -> Bool {
        guard Thread.isMainThread else {
            return shouldEnableJetpackFeatures()
        }
        return jetpackFeaturesEnabled(rootViewCoordinator: .shared)
    }

    /// Used to determine if the Jetpack features are enabled based on the current app UI type.
    /// This way we ensure features are not removed before reloading the UI.
    /// But if this function is called from a background thread, we determine if the Jetpack Features
    /// are enabled based on the removal phase regardless of the app UI state.
    /// Using two separate methods (rather than one method with a default argument) because Obj-C.
    /// - Returns: `true` if UI type is normal, and `false` if UI type is simplified.
    static func jetpackFeaturesEnabled(rootViewCoordinator: RootViewCoordinator) -> Bool {
        guard Thread.isMainThread else {
            return shouldEnableJetpackFeatures()
        }
        return rootViewCoordinator.currentAppUIType == .normal
    }


    /// Used to determine if the Jetpack features are enabled based on the removal phase regardless of the app UI state.
    private static func shouldEnableJetpackFeatures(featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore()) -> Bool {
        let phase = generalPhase()
        switch phase {
        case .four, .newUsers, .selfHosted:
            return false
        default:
            return true
        }
    }

    /// Used to display feature-specific or feature-collection overlays.
    /// - Parameters:
    ///   - viewController: The view controller where the overlay should be presented in.
    ///   - source: The source that triggers the display of the overlay.
    ///   - forced: Pass `true` to override the overlay frequency logic. Default is `false`.
    ///   - fullScreen: If `true` and not on iPad, the fullscreen modal presentation type is used.
    ///   Else the form sheet type is used. Default is `false`.
    ///   - blog: `Blog` object used to determine if Jetpack is installed in case of the self-hosted phase.
    ///   - onWillDismiss: Callback block to be called when the overlay is about to be dismissed.
    ///   - onDidDismiss: Callback block to be called when the overlay has finished dismissing.
    static func presentOverlayIfNeeded(in viewController: UIViewController,
                                       source: JetpackOverlaySource,
                                       forced: Bool = false,
                                       fullScreen: Bool = false,
                                       blog: Blog? = nil,
                                       onWillDismiss: JetpackOverlayDismissCallback? = nil,
                                       onDidDismiss: JetpackOverlayDismissCallback? = nil) {
        let phase = generalPhase()
        let frequencyConfig = phase.frequencyConfig
        let frequencyTrackerPhaseString = source.frequencyTrackerPhaseString(phase: phase)

        let coordinator = JetpackDefaultOverlayCoordinator()
        let viewModel = JetpackFullscreenOverlayGeneralViewModel(phase: phase, source: source, blog: blog, coordinator: coordinator)
        let overlayViewController = JetpackFullscreenOverlayViewController(with: viewModel)
        let navigationViewController = UINavigationController(rootViewController: overlayViewController)
        coordinator.navigationController = navigationViewController
        coordinator.viewModel = viewModel
        viewModel.onWillDismiss = onWillDismiss
        viewModel.onDidDismiss = onDidDismiss
        let frequencyTracker = OverlayFrequencyTracker(source: source,
                                                       type: .featuresRemoval,
                                                       frequencyConfig: frequencyConfig,
                                                       phaseString: frequencyTrackerPhaseString)
        guard viewModel.shouldShowOverlay, frequencyTracker.shouldShow(forced: forced) else {
            onWillDismiss?()
            onDidDismiss?()
            return
        }
        presentOverlay(navigationViewController: navigationViewController, in: viewController, fullScreen: fullScreen)
        frequencyTracker.track()
    }

    /// Used to display Site Creation overlays.
    /// - Parameters:
    ///   - viewController: The view controller where the overlay should be presented in.
    ///   - source: The source that triggers the display of the overlay.
    ///   - onWillDismiss: Callback block to be called when the overlay is about to be dismissed.
    ///   - onDidDismiss: Callback block to be called when the overlay has finished dismissing.
    static func presentSiteCreationOverlayIfNeeded(in viewController: UIViewController,
                                                   source: String,
                                                   onWillDismiss: JetpackOverlayDismissCallback? = nil,
                                                   onDidDismiss: JetpackOverlayDismissCallback? = nil) {
        let phase = siteCreationPhase()
        let coordinator = JetpackDefaultOverlayCoordinator()
        //
        let viewModel = JetpackFullscreenOverlaySiteCreationViewModel(
            phase: phase,
            source: source,
            coordinator: coordinator
        )
        let overlayViewController = JetpackFullscreenOverlayViewController(with: viewModel)
        let navigationViewController = UINavigationController(rootViewController: overlayViewController)
        coordinator.viewModel = viewModel
        viewModel.onWillDismiss = onWillDismiss
        viewModel.onDidDismiss = onDidDismiss
        guard viewModel.shouldShowOverlay else {
            onWillDismiss?()
            onDidDismiss?()
            return
        }
        presentOverlay(navigationViewController: navigationViewController, in: viewController)
    }

    private static func presentOverlay(navigationViewController: UINavigationController,
                                       in viewController: UIViewController,
                                       fullScreen: Bool = false) {
        let shouldUseFormSheet = WPDeviceIdentification.isiPad() || !fullScreen
        navigationViewController.modalPresentationStyle = shouldUseFormSheet ? .formSheet : .fullScreen

        viewController.present(navigationViewController, animated: true)
    }
}
