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
        case staticScreens = "static_screens"

        func frequencyConfig(remoteConfigStore: RemoteConfigStore = RemoteConfigStore()) -> OverlayFrequencyTracker.FrequencyConfig {
            switch self {
            case .one:
                fallthrough
            case .two:
                return .init(featureSpecificInDays: 7, generalInDays: 2)
            case .three:
                return .init(featureSpecificInDays: 4, generalInDays: 1)
            case .four:
                let frequency: Int? = RemoteConfigParameter.phaseFourOverlayFrequency.value(using: remoteConfigStore)
                return .init(featureSpecificInDays: 0, generalInDays: frequency ?? -1)
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
        case phaseFourOverlay = "phase_four_overlay"

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
            case .phaseFourOverlay:
                return .respectFrequencyConfig
            }
        }
    }

    static var currentAppUIType: RootViewCoordinator.AppUIType?

    static func generalPhase(featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore()) -> GeneralPhase {
        if AppConfiguration.isJetpack {
            return .normal // Always return normal for Jetpack
        }


        if AccountHelper.noWordPressDotComAccount {
            let selfHostedRemoval = RemoteFeatureFlag.jetpackFeaturesRemovalPhaseSelfHosted.enabled(using: featureFlagStore)
            return selfHostedRemoval ? .selfHosted : .normal
        }
        if RemoteFeatureFlag.jetpackFeaturesRemovalPhaseNewUsers.enabled(using: featureFlagStore) {
            return .newUsers
        }
        if RemoteFeatureFlag.jetpackFeaturesRemovalPhaseFour.enabled(using: featureFlagStore) {
            return .four
        }
        if RemoteFeatureFlag.jetpackFeaturesRemovalStaticPosters.enabled(using: featureFlagStore) {
            return .staticScreens
        }
        if RemoteFeatureFlag.jetpackFeaturesRemovalPhaseThree.enabled(using: featureFlagStore) {
            return .three
        }
        if RemoteFeatureFlag.jetpackFeaturesRemovalPhaseTwo.enabled(using: featureFlagStore) {
            return .two
        }
        if RemoteFeatureFlag.jetpackFeaturesRemovalPhaseOne.enabled(using: featureFlagStore) {
            return .one
        }

        return .normal
    }

    static func siteCreationPhase(
        featureFlagStore: RemoteFeatureFlagStore = RemoteFeatureFlagStore(),
        blog: Blog? = nil
    ) -> SiteCreationPhase {
        if AppConfiguration.isJetpack {
            return .normal // Always return normal for Jetpack
        }

        if RemoteFeatureFlag.jetpackFeaturesRemovalPhaseNewUsers.enabled(using: featureFlagStore)
            || RemoteFeatureFlag.jetpackFeaturesRemovalPhaseFour.enabled(using: featureFlagStore)
            || RemoteFeatureFlag.jetpackFeaturesRemovalStaticPosters.enabled(using: featureFlagStore) {
            return blog?.hasDomains == true ? .two : .normal
        }
        if RemoteFeatureFlag.jetpackFeaturesRemovalPhaseThree.enabled(using: featureFlagStore)
            || RemoteFeatureFlag.jetpackFeaturesRemovalPhaseTwo.enabled(using: featureFlagStore)
            || RemoteFeatureFlag.jetpackFeaturesRemovalPhaseOne.enabled(using: featureFlagStore) {
            return .one
        }

        return .normal
    }

    static func removalDeadline(remoteConfigStore: RemoteConfigStore = RemoteConfigStore()) -> Date? {
        guard let dateString: String = RemoteConfigParameter.jetpackDeadline.value(using: remoteConfigStore) else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    /// Used to determine if the Jetpack features are enabled based on the current app UI type.
    /// But if the current app UI type is not set, we determine if the Jetpack Features
    /// are enabled based on the removal phase regardless of the app UI state.
    /// It is possible for JP features to be disabled, but still be displayed (`shouldShowJetpackFeatures`)
    /// This will happen in the "Static Screens" phase.
    @objc
    static func jetpackFeaturesEnabled() -> Bool {
        return jetpackFeaturesEnabled(featureFlagStore: RemoteFeatureFlagStore())
    }

    /// Used to determine if the Jetpack features are enabled based on the current app UI type.
    /// But if the current app UI type is not set, we determine if the Jetpack Features
    /// are enabled based on the removal phase regardless of the app UI state.
    /// It is possible for JP features to be disabled, but still be displayed (`shouldShowJetpackFeatures`)
    /// This will happen in the "Static Screens" phase.
    /// Using two separate methods (rather than one method with a default argument) because Obj-C.
    static func jetpackFeaturesEnabled(featureFlagStore: RemoteFeatureFlagStore) -> Bool {
        guard let currentAppUIType else {
            return shouldEnableJetpackFeaturesBasedOnCurrentPhase(featureFlagStore: featureFlagStore)
        }
        return currentAppUIType == .normal
    }

    /// Used to determine if the Jetpack features are to be displayed based on the current app UI type.
    /// This way we ensure features are not removed before reloading the UI.
    /// But if the current app UI type is not set, we determine if the Jetpack Features
    /// are to be displayed based on the removal phase regardless of the app UI state.
    @objc
    static func shouldShowJetpackFeatures() -> Bool {
        return shouldShowJetpackFeatures(featureFlagStore: RemoteFeatureFlagStore())
    }

    /// Used to determine if the Jetpack features are to be displayed based on the current app UI type.
    /// This way we ensure features are not removed before reloading the UI.
    /// But if the current app UI type is not set, we determine if the Jetpack Features
    /// are to be displayed based on the removal phase regardless of the app UI state.
    /// Using two separate methods (rather than one method with a default argument) because Obj-C.
    static func shouldShowJetpackFeatures(featureFlagStore: RemoteFeatureFlagStore) -> Bool {
        guard let currentAppUIType else {
            return shouldShowJetpackFeaturesBasedOnCurrentPhase(featureFlagStore: featureFlagStore)
        }
        return currentAppUIType != .simplified
    }


    /// Used to determine if the Jetpack features are to be displayed or not based on the removal phase regardless of the app UI state.
    private static func shouldShowJetpackFeaturesBasedOnCurrentPhase(featureFlagStore: RemoteFeatureFlagStore) -> Bool {
        let phase = generalPhase(featureFlagStore: featureFlagStore)
        switch phase {
        case .four, .newUsers, .selfHosted:
            return false
        default:
            return true
        }
    }

    /// Used to determine if the Jetpack features are enabled or not based on the removal phase regardless of the app UI state.
    private static func shouldEnableJetpackFeaturesBasedOnCurrentPhase(featureFlagStore: RemoteFeatureFlagStore) -> Bool {
        let phase = generalPhase(featureFlagStore: featureFlagStore)
        switch phase {
        case .four, .newUsers, .selfHosted, .staticScreens:
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
        let frequencyConfig = phase.frequencyConfig()
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
