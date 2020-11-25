import Intents

class IntentHandler: INExtension, /* INSendMessageIntentHandling, INSearchForMessagesIntentHandling, INSetMessageAttributeIntentHandling,*/ SelectSiteIntentHandling {

    override func handler(for intent: INIntent) -> Any {
        return self
    }
    
    // MARK: - SelectSiteIntentHandling

    func resolveSite(for intent: SelectSiteIntent, with completion: @escaping (SiteResolutionResult) -> Void) {
        print("asd!")
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

    private func icon(from data: HomeWidgetTodayData) -> INImage? {
        guard let iconURL = data.iconURL,
              let url = URL(string: iconURL) else {
            return nil
        }

        return INImage(url: url)
    }
}
