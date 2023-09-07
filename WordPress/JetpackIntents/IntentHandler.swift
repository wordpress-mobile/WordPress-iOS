import Intents

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
