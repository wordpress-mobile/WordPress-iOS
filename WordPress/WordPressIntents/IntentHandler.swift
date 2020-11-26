import Intents
import IntentsUI

class SitesDataProvider {
    private(set) var sites = [Site]()

    init() {
        initializeSites()
    }

    var defaultSite: Site {
        // TODO: return the default site correctly... this is lazy :P
        sites[0]
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
        // Not sure yet what this is for... but we can't remove it because it causes a build error.
        // - diegoreymendez
    }

    func provideSiteOptionsCollection(for intent: SelectSiteIntent, with completion: @escaping (INObjectCollection<Site>?, Error?) -> Void) {
        let sitesCollection = INObjectCollection<Site>(items: sitesDataProvider.sites)

        completion(sitesCollection, nil)
    }
}
