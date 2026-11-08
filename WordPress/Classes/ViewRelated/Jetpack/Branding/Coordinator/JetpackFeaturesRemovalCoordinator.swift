import Foundation
import BuildSettingsKit
import WordPressData
import WordPressShared

/// A class containing convenience methods for the the Jetpack features removal experience
public class JetpackFeaturesRemovalCoordinator: NSObject {

    /// Enum describing the current phase of the Jetpack features removal
    enum GeneralPhase: String {
        case normal
        case selfHosted = "self_hosted"
        case staticScreens = "static_screens"
    }

    /// Enum describing the current phase of the site creation flow removal
    enum SiteCreationPhase: String {
        case normal
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
            rawValue
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

    static var currentAppUIType: RootViewCoordinator.AppUIType?

    /// `RemoteFeatureFlag.readerInWordPressApp`, read once per launch: a fetch that changes the
    /// flag applies on the next launch.
    ///
    /// The flag decides both the app UI type and the scope of the Notifications lists. Reading it
    /// live could make them disagree: a list created after a fetch would get the new scope while
    /// the root UI kept the old type. Tests may set it.
    static var isReaderInWordPressAppEnabled = RemoteFeatureFlag.readerInWordPressApp.enabled()

    /// The WordPress app shows static screens to WordPress.com users and the simplified UI to everyone else.
    /// Other apps show every feature.
    static func generalPhase(
        app: AppBrand = BuildSettings.current.brand,
        hasDotComAccount: @autoclosure () -> Bool = !AccountHelper.noWordPressDotComAccount
    ) -> GeneralPhase {
        guard app == .wordpress else {
            return .normal
        }
        return hasDotComAccount() ? .staticScreens : .selfHosted
    }

    /// In the WordPress app, users who already have a site see a Jetpack overlay instead of the site creation flow.
    static func siteCreationPhase(
        app: AppBrand = BuildSettings.current.brand,
        hasBlog: @autoclosure () -> Bool = JetpackFeaturesRemovalCoordinator.hasBlog()
    ) -> SiteCreationPhase {
        guard app == .wordpress else {
            return .normal
        }
        return hasBlog() ? .two : .normal
    }

    /// Used to determine if the Jetpack features are enabled based on the current app UI type.
    /// But if the current app UI type is not set, we determine if the Jetpack Features
    /// are enabled based on the removal phase regardless of the app UI state.
    /// It is possible for JP features to be disabled, but still be displayed (`shouldShowJetpackFeatures`)
    /// This will happen in the "Static Screens" phase.
    @objc
    public static func jetpackFeaturesEnabled() -> Bool {
        guard let currentAppUIType else {
            return shouldEnableJetpackFeaturesBasedOnCurrentPhase()
        }
        return currentAppUIType == .normal
    }

    /// Used to determine if the Jetpack features are to be displayed based on the current app UI type.
    /// This way we ensure features are not removed before reloading the UI.
    /// But if the current app UI type is not set, we determine if the Jetpack Features
    /// are to be displayed based on the removal phase regardless of the app UI state.
    @objc
    public static func shouldShowJetpackFeatures() -> Bool {
        guard let currentAppUIType else {
            return shouldShowJetpackFeaturesBasedOnCurrentPhase()
        }
        return currentAppUIType != .simplified
    }

    /// Whether Reader is live rather than the Moved-to-Jetpack poster.
    ///
    /// Unlike `jetpackFeaturesEnabled()`, this is also true in `staticScreensWithReader`.
    /// Use it only to decide whether to navigate into Reader, never to gate push notifications,
    /// prompts, or other Jetpack features.
    static func isReaderAvailable() -> Bool {
        jetpackFeaturesEnabled() || isStaticScreensWithReader()
    }

    static func isStaticScreensWithReader() -> Bool {
        currentAppUIType == .staticScreensWithReader
    }

    /// Used to determine if the Jetpack features are to be displayed or not based on the removal phase regardless of the app UI state.
    private static func shouldShowJetpackFeaturesBasedOnCurrentPhase() -> Bool {
        generalPhase() != .selfHosted
    }

    /// Used to determine if the Jetpack features are enabled or not based on the removal phase regardless of the app UI state.
    private static func shouldEnableJetpackFeaturesBasedOnCurrentPhase() -> Bool {
        generalPhase() == .normal
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
    static func presentOverlayIfNeeded(
        in viewController: UIViewController,
        source: JetpackOverlaySource,
        forced: Bool = false,
        fullScreen: Bool = false,
        blog: Blog? = nil,
        onWillDismiss: JetpackOverlayDismissCallback? = nil,
        onDidDismiss: JetpackOverlayDismissCallback? = nil
    ) {
        let phase = generalPhase()
        let frequencyTrackerPhaseString = source.frequencyTrackerPhaseString(phase: phase)

        let coordinator = JetpackDefaultOverlayCoordinator()
        let viewModel = JetpackFullscreenOverlayGeneralViewModel(
            phase: phase,
            source: source,
            blog: blog,
            coordinator: coordinator
        )
        let frequencyTracker = OverlayFrequencyTracker(
            source: source,
            type: .featuresRemoval,
            phaseString: frequencyTrackerPhaseString
        )
        guard viewModel.shouldShowOverlay, frequencyTracker.shouldShow(forced: forced) else {
            onWillDismiss?()
            onDidDismiss?()
            return
        }
        let overlayViewController = JetpackFullscreenOverlayViewController(with: viewModel)
        let navigationViewController = UINavigationController(rootViewController: overlayViewController)
        coordinator.navigationController = navigationViewController
        coordinator.viewModel = viewModel
        viewModel.onWillDismiss = onWillDismiss
        viewModel.onDidDismiss = onDidDismiss
        presentOverlay(navigationViewController: navigationViewController, in: viewController, fullScreen: fullScreen)
        frequencyTracker.track()
    }

    /// Used to display Site Creation overlays.
    /// - Parameters:
    ///   - viewController: The view controller where the overlay should be presented in.
    ///   - source: The source that triggers the display of the overlay.
    ///   - onWillDismiss: Callback block to be called when the overlay is about to be dismissed.
    ///   - onDidDismiss: Callback block to be called when the overlay has finished dismissing.
    static func presentSiteCreationOverlayIfNeeded(
        in viewController: UIViewController,
        source: String,
        onWillDismiss: JetpackOverlayDismissCallback? = nil,
        onDidDismiss: JetpackOverlayDismissCallback? = nil
    ) {
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

    static func presentOverlay(
        navigationViewController: UINavigationController,
        in viewController: UIViewController,
        fullScreen: Bool = false
    ) {
        let windowSizeClass = viewController.view.window?.traitCollection.horizontalSizeClass
        let shouldUseFormSheet = windowSizeClass == .regular || !fullScreen
        navigationViewController.modalPresentationStyle = shouldUseFormSheet ? .formSheet : .fullScreen

        viewController.present(navigationViewController, animated: true)
    }

    private static func hasBlog() -> Bool {
        Blog.count(in: ContextManager.shared.mainContext) > 0
    }
}
