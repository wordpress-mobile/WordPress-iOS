import Intents
import IntentsUI

class SitesDataProvider {
    private(set) var sites = [Site]()

    init() {
        initializeSites()
    }

    // MARK: - Default Site
    
    private var defaultSiteID: Int? {
        // TODO - TODAYWIDGET: taking the default site id from user defaults for now.
        // This would change if the old widget gets reconfigured to a different site than the default.
        return UserDefaults(suiteName: WPAppGroupName)?.object(forKey: WPStatsTodayWidgetUserDefaultsSiteIdKey) as? Int
    }
    
    var defaultSite: Site? {
        guard let defaultSiteID = self.defaultSiteID else {
            return nil
        }
        
        return sites[defaultSiteID]
    }

    private func initializeSites() {
        guard let data = HomeWidgetTodayData.read() else {
            sites = []
            return
        }

        sites = data.map { (key: Int, data: HomeWidgetTodayData) -> Site in
            let icon = self.icon(from: data)

            return Site(
                identifier: String(key),
                display: data.siteName,
                subtitle: nil,
                image: icon)
        }
    }

    // MARK: - Site Icons

    private func icon(from data: HomeWidgetTodayData) -> INImage {
        guard let iconURL = data.iconURL,
              let url = URL(string: iconURL),
              let image = INImage(url: url) else {

            return INImage(named: "blavatar-default")
        }

        return image
    }
}

class IntentHandler: INExtension, SelectSiteIntentHandling {

    let sitesDataProvider = SitesDataProvider()

    // MARK: - INIntentHandlerProviding

    override func handler(for intent: INIntent) -> Any {
        return self
    }

    // MARK: - SelectSiteIntentHandling

    func defaultSite(for intent: SelectSiteIntent) -> Site? {
        return sitesDataProvider.defaultSite
    }

    func resolveSite(for intent: SelectSiteIntent, with completion: @escaping (SiteResolutionResult) -> Void) {
        /// - TODO: I have to test if this method can be called by interacting with Siri, and define an implementation.  This is probably called whenever you ask the selected site, since the value can theoretically be requested through Siri.  Check out Widgets.intentdefinition.
    }

    func provideSiteOptionsCollection(for intent: SelectSiteIntent, with completion: @escaping (INObjectCollection<Site>?, Error?) -> Void) {
        let sitesCollection = INObjectCollection<Site>(items: sitesDataProvider.sites)

        completion(sitesCollection, nil)
    }
}
