@objcMembers
class JetpackInstallPluginHelper: NSObject {

    private static var cardHiddenSites: [String] {
        get {
            guard let sites = UserPersistentStoreFactory.instance().array(forKey: Constants.cardHiddenSitesKey) as? [String] else {
                return [String]()
            }
            return sites
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: Constants.cardHiddenSitesKey)
        }
    }

    static func shouldShow(for blog: Blog?) -> Bool {
        guard let blog, blog.account != nil else {
            return false
        }
        let isFeatureEnabled = FeatureFlag.jetpackIndividualPluginSupport.enabled
        return isFeatureEnabled && blog.jetpackIsConnectedWithoutFullPlugin
    }

    static func shouldShowCard(for blog: Blog?) -> Bool {
        guard let siteID = blog?.dotComID?.stringValue else {
            return false
        }
        let isCardHidden = cardHiddenSites.contains { $0 == siteID }
        return shouldShow(for: blog) && !isCardHidden
    }

    static func hideCard(for blog: Blog?) {
        guard let blog, let siteID = blog.dotComID?.stringValue else {
            return
        }

        var sites = cardHiddenSites
        sites.append(siteID)
        cardHiddenSites = sites
    }

    private struct Constants {
        static let cardHiddenSitesKey = "jetpack-install-card-hidden-sites"
    }

}
