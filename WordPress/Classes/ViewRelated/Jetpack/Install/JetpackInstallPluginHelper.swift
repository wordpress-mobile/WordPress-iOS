@objc
class JetpackInstallPluginHelper: NSObject {

    // MARK: Dependencies

    private let repository: UserPersistentRepository
    private let blog: Blog
    private let siteIDString: String

    var shouldShowCard: Bool {
        shouldPromptInstall && !isCardHidden
    }

    var shouldShowOverlay: Bool {
        shouldPromptInstall && !isOverlayAlreadyShown
    }

    // MARK: Methods

    @objc
    static func shouldShowCard(for blog: Blog?) -> Bool {
        return JetpackInstallPluginHelper(blog)?.shouldShowCard ?? false
    }

    @objc
    static func shouldShowOverlay(for blog: Blog?) -> Bool {
        return JetpackInstallPluginHelper(blog)?.shouldPromptInstall ?? false
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
            (repository.array(forKey: .cardHiddenSitesKey) as? [String]) ?? [String]()
        }
        set {
            repository.set(newValue, forKey: .cardHiddenSitesKey)
        }
    }

    var isOverlayAlreadyShown: Bool {
        overlayShownSites.contains { $0 == siteIDString }
    }

    var overlayShownSites: [String] {
        get {
            (repository.array(forKey: .overlayShownSitesKey) as? [String]) ?? [String]()
        }
        set {
            repository.set(newValue, forKey: .overlayShownSitesKey)
        }
    }

    var shouldPromptInstall: Bool {
        blog.jetpackIsConnectedWithoutFullPlugin
    }
}

// MARK: - String Constants

private extension String {
    static let cardHiddenSitesKey = "jetpack-install-card-hidden-sites"
    static let overlayShownSitesKey = "jetpack-install-overlay-shown-sites"
}
