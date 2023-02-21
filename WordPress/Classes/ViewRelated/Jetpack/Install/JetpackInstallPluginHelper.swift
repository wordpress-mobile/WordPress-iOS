@objc
class JetpackInstallPluginHelper: NSObject {

    // MARK: Dependencies

    private let repository: UserPersistentRepository
    private let blog: Blog
    private let siteIDString: String

    /// Determines whether the install cards should be shown for this `blog` in the My Site screen.
    var shouldShowCard: Bool {
        shouldPromptInstall && !isCardHidden
    }

    /// Determines whether the plugin install overlay should be shown for this `blog`.
    var shouldShowOverlay: Bool {
        shouldPromptInstall && !isOverlayAlreadyShown
    }

    // MARK: Methods

    /// Convenient static method that determines whether we should show the install cards for the given `blog`.
    ///
    /// - Parameter blog: The `Blog` to show the install cards for,
    /// - Returns: True if the install cards should be shown for this blog.
    @objc static func shouldShowCard(for blog: Blog?) -> Bool {
        return JetpackInstallPluginHelper(blog)?.shouldShowCard ?? false
    }

    /// Convenience entry point to show the Jetpack Install Plugin overlay when needed.
    /// The overlay will only be shown when:
    ///     1. User accesses this `Blog` via their WordPress.com account,
    ///     2. The `Blog` has individual Jetpack plugin(s) installed, without the full Jetpack plugin,
    ///     3. The overlay has never been shown for this site before (overrideable by setting `force` to `true`).
    ///
    /// - Parameters:
    ///   - blog: The Blog that might need the full Jetpack plgin.
    ///   - presentingViewController: The view controller that will be presenting the overlay.
    ///   - force: Whether the overlay should be shown regardless if the overlay has been shown previously.
    static func presentOverlayIfNeeded(in presentingViewController: UIViewController,
                                       blog: Blog?,
                                       delegate: JetpackRemoteInstallDelegate?,
                                       force: Bool = false) {
        guard let blog,
              let siteURLString = blog.displayURL as? String, // just the host URL without the scheme.
              let plugin = JetpackPlugin(from: blog.jetpackConnectionActivePlugins),
              let helper = JetpackInstallPluginHelper(blog),
              helper.shouldShowOverlay || force else {
            return
        }

        // create the overlay stack.
        let viewModel = JetpackPluginOverlayViewModel(siteName: siteURLString, plugin: plugin)
        let overlayViewController = JetpackFullscreenOverlayViewController(with: viewModel)
        let coordinator = JetpackPluginOverlayCoordinator(blog: blog,
                                                          viewController: overlayViewController,
                                                          installDelegate: delegate)
        viewModel.coordinator = coordinator

        // present the overlay.
        let navigationViewController = UINavigationController(rootViewController: overlayViewController)
        let shouldUseFormSheet = WPDeviceIdentification.isiPad()
        navigationViewController.modalPresentationStyle = shouldUseFormSheet ? .formSheet : .fullScreen
        presentingViewController.present(navigationViewController, animated: true) {
            helper.markOverlayAsShown()
        }
    }

    init?(_ blog: Blog?, repository: UserPersistentRepository = UserPersistentStoreFactory.instance()) {
        guard let blog,
              let siteID = blog.dotComID?.stringValue,
              blog.account != nil,
              FeatureFlag.jetpackIndividualPluginSupport.enabled else {
            return nil
        }

        self.blog = blog
        self.siteIDString = siteID
        self.repository = repository
    }

    func hideCard() {
        if isCardHidden {
            return
        }
        cardHiddenSites += [siteIDString]
    }

    func markOverlayAsShown() {
        if isOverlayAlreadyShown {
            return
        }
        overlayShownSites += [siteIDString]
    }
}

// MARK: - Private Helpers

private extension JetpackInstallPluginHelper {

    var isCardHidden: Bool {
        cardHiddenSites.contains { $0 == siteIDString }
    }

    var cardHiddenSites: [String] {
        get {
            (repository.array(forKey: Constants.cardHiddenSitesKey) as? [String]) ?? [String]()
        }
        set {
            repository.set(newValue, forKey: Constants.cardHiddenSitesKey)
        }
    }

    var isOverlayAlreadyShown: Bool {
        overlayShownSites.contains { $0 == siteIDString }
    }

    var overlayShownSites: [String] {
        get {
            (repository.array(forKey: Constants.overlayShownSitesKey) as? [String]) ?? [String]()
        }
        set {
            repository.set(newValue, forKey: Constants.overlayShownSitesKey)
        }
    }

    var shouldPromptInstall: Bool {
        blog.jetpackIsConnectedWithoutFullPlugin
    }

    struct Constants {
        static let cardHiddenSitesKey = "jetpack-install-card-hidden-sites"
        static let overlayShownSitesKey = "jetpack-install-overlay-shown-sites"
    }
}
