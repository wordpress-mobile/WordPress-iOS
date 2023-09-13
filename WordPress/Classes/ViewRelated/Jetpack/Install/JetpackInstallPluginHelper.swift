@objc
class JetpackInstallPluginHelper: NSObject {

    // MARK: Dependencies

    private let repository: UserPersistentRepository
    private let currentDateProvider: CurrentDateProvider
    private let remoteConfigStore: RemoteConfigStore
    private let receipt: RecentJetpackInstallReceipt
    private let blog: Blog
    private let siteIDString: String

    /// Determines whether the install cards should be shown for this `blog` in the My Site screen.
    var shouldShowCard: Bool {
        shouldPromptInstall && !isCardHidden
    }

    /// Determines whether the plugin install overlay should be shown for this `blog`.
    var shouldShowOverlay: Bool {
        if AppConfiguration.isJetpack {
            // For Jetpack, the overlay will be shown once per site.
            return shouldPromptInstall && !isOverlayAlreadyShown
        }

        return shouldShowOverlayInWordPress
    }

    // MARK: Methods

    /// Convenient static method that determines whether we should show the install cards for the given `blog`.
    ///
    /// - Parameter blog: The `Blog` to show the install cards for,
    /// - Returns: True if the install cards should be shown for this blog.
    @objc static func shouldShowCard(for blog: Blog?) -> Bool {
        // cards are only shown in Jetpack.
        guard AppConfiguration.isJetpack,
              let helper = JetpackInstallPluginHelper(blog) else {
            return false
        }

        return helper.shouldShowCard
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
        var coordinator: JetpackOverlayCoordinator?

        // present the overlay.
        let navigationViewController = UINavigationController(rootViewController: overlayViewController)
        if AppConfiguration.isWordPress {
            let defaultCoordinator = JetpackDefaultOverlayCoordinator()
            defaultCoordinator.navigationController = navigationViewController
            coordinator = defaultCoordinator
        } else {
            coordinator = JetpackPluginOverlayCoordinator(blog: blog,
                                                          viewController: overlayViewController,
                                                          installDelegate: delegate)
        }
        viewModel.coordinator = coordinator
        let shouldUseFormSheet = WPDeviceIdentification.isiPad()
        navigationViewController.modalPresentationStyle = shouldUseFormSheet ? .formSheet : .fullScreen
        presentingViewController.present(navigationViewController, animated: true) {
            helper.markOverlayAsShown()
        }
    }

    init?(_ blog: Blog?,
          repository: UserPersistentRepository = UserPersistentStoreFactory.instance(),
          currentDateProvider: CurrentDateProvider = DefaultCurrentDateProvider(),
          remoteConfigStore: RemoteConfigStore = .init(),
          receipt: RecentJetpackInstallReceipt = .shared) {
        guard let blog,
              let siteID = blog.dotComID?.stringValue,
              blog.account != nil,
              JetpackInstallPluginHelper.isFeatureEnabled else {
            return nil
        }

        self.blog = blog
        self.siteIDString = siteID
        self.repository = repository
        self.currentDateProvider = currentDateProvider
        self.remoteConfigStore = remoteConfigStore
        self.receipt = receipt
    }

    func hideCard() {
        if isCardHidden {
            return
        }
        cardHiddenSites += [siteIDString]
    }

    func markOverlayAsShown() {
        guard AppConfiguration.isJetpack else {
            markOverlayShownInWordPress()
            return
        }

        if isOverlayAlreadyShown {
            return
        }
        overlayShownSites += [siteIDString]
    }
}

// MARK: - Private Helpers

private extension JetpackInstallPluginHelper {

    static var isFeatureEnabled: Bool {
        if AppConfiguration.isJetpack {
            return true
        }

        return RemoteFeatureFlag.wordPressIndividualPluginSupport.enabled()
    }

    /// Returns true if the card has been set to hidden for `blog`. For Jetpack only.
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

    /// Returns true if the overlay has been shown for `blog`. For Jetpack only.
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
        blog.jetpackIsConnectedWithoutFullPlugin && !receipt.installed(for: siteIDString)
    }

    // MARK: Constants

    struct Constants {
        static let cardHiddenSitesKey = "jetpack-install-card-hidden-sites"
        static let overlayShownSitesKey = "jetpack-install-overlay-shown-sites"
    }
}

// MARK: - Recent Jetpack Install Receipt

/// A simple helper class that tracks recent Jetpack installations in-memory.
/// This is done to help keep things updated as soon as the plugin is installed.
/// Otherwise, we'd have to manually call sync from each callsites, wait for them to complete, and _then_ update.
class RecentJetpackInstallReceipt {
    private(set) static var shared = RecentJetpackInstallReceipt()

    private var siteIDs = Set<String>()

    func installed(for siteID: String) -> Bool {
        return siteIDs.contains(siteID)
    }

    func store(_ siteID: String) {
        siteIDs.insert(siteID)
    }
}

// MARK: - WordPress Helpers

private extension JetpackInstallPluginHelper {

    var maxOverlayShownPerSite: Int {
        RemoteConfigParameter.wordPressPluginOverlayMaxShown.value(using: remoteConfigStore) ?? 0
    }

    var shouldShowOverlayInWordPress: Bool {
        let overlayInfo = WordPressOverlayInfo(siteID: siteIDString,
                                               repository: repository,
                                               currentDateProvider: currentDateProvider)

        guard overlayInfo.amountShown < maxOverlayShownPerSite,
              currentDateProvider.date() >= overlayInfo.nextOccurrence else {
            return false
        }

        return shouldPromptInstall
    }

    func markOverlayShownInWordPress() {
        let overlayInfo = WordPressOverlayInfo(siteID: siteIDString,
                                               repository: repository,
                                               currentDateProvider: currentDateProvider)

        overlayInfo.updateNextOccurrence()
    }
}

private class WordPressOverlayInfo {
    private static let dateFormatter = ISO8601DateFormatter()
    private let siteID: String
    private let repository: UserPersistentRepository
    private let currentDateProvider: CurrentDateProvider

    /// Tracks the overlay occurrences for all sites in dictionary format.
    ///
    /// The occurrences are stored as an array of date strings, and the amount of strings tell how many times
    /// the overlay has been shown for the site.
    ///
    /// For example, given `["2023-03-17 17:00", "2023-03-25 11:00"]`, this tells that:
    ///     - The overlay has been shown 2 times, and
    ///     - The third overlay may be shown after 2023-03-25 11:00.
    ///
    private var overlayOccurrenceSites: [String: [String]] {
        get {
            (repository.dictionary(forKey: Constants.overlayOccurrenceSitesKey) as? [String: [String]]) ?? .init()
        }
        set {
            repository.set(newValue, forKey: Constants.overlayOccurrenceSitesKey)
        }
    }

    /// How many times the overlay has been shown for the site.
    var amountShown: Int {
        overlayOccurrenceSites[siteID]?.count ?? 0
    }

    /// The minimum date before the overlay can be shown again for the site.
    private(set) var nextOccurrence: Date {
        get {
            guard let dateString = overlayOccurrenceSites[siteID]?.last,
                  let date = Self.dateFormatter.date(from: dateString) else {
                return .distantPast
            }
            return date
        }
        set {
            var mutableDictionary = overlayOccurrenceSites
            var occurrencesForSite = mutableDictionary[siteID] ?? [String]()
            occurrencesForSite.append(Self.dateFormatter.string(from: newValue))
            mutableDictionary[siteID] = occurrencesForSite

            overlayOccurrenceSites = mutableDictionary
        }
    }

    init(siteID: String, repository: UserPersistentRepository, currentDateProvider: CurrentDateProvider) {
        self.siteID = siteID
        self.repository = repository
        self.currentDateProvider = currentDateProvider
    }

    func updateNextOccurrence() {
        nextOccurrence = currentDateProvider.date().addingTimeInterval(delay(after: amountShown + 1))
    }

    private func delay(after amountShown: Int) -> TimeInterval {
        switch amountShown {
        case 1:
            return Constants.oneDayInterval
        case 2:
            return Constants.threeDaysInterval
        default:
            return Constants.oneWeekInterval
        }
    }

    private struct Constants {
        static let overlayOccurrenceSitesKey = "jetpack-install-overlay-occurrence-sites"
        static let oneDayInterval: TimeInterval = 60 * 60 * 24
        static let threeDaysInterval: TimeInterval = oneDayInterval * 3
        static let oneWeekInterval: TimeInterval = oneDayInterval * 7
    }
}
