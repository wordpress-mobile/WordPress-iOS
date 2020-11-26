import Intents
import IntentsUI

class IntentHandler: INExtension, SelectSiteIntentHandling {

    override func handler(for intent: INIntent) -> Any {
        return self
    }
    
    // MARK: - SelectSiteIntentHandling
    
    func defaultSite(for intent: SelectSiteIntent) -> Site? {
        return nil
    }

    func resolveSite(for intent: SelectSiteIntent, with completion: @escaping (SiteResolutionResult) -> Void) {
        // Not sure yet what this is for... but we can't remove it because it causes a build error.
        // - diegoreymendez
    }

    func provideSiteOptionsCollection(for intent: SelectSiteIntent, with completion: @escaping (INObjectCollection<Site>?, Error?) -> Void) {

        guard let data = HomeWidgetTodayData.read() else {
            return
        }

        let sites = data.map { (key: Int, data: HomeWidgetTodayData) -> Site in
            let icon = self.icon(from: data)

            return Site(
                identifier: String(key),
                display: data.siteName,
                subtitle: nil,
                image: icon)
        }

        let sitesCollection = INObjectCollection<Site>(items: sites)

        completion(sitesCollection, nil)
    }

    // MARK: - Site Image

    private func icon(from data: HomeWidgetTodayData) -> INImage {
        guard let iconURL = data.iconURL,
              let url = URL(string: iconURL),
              let image = INImage(url: url) else {
            
            return INImage(named: "blavatar-default")
        }

        return image
    }
}

