import Intents

class SitesDataProvider {
    private(set) var sites = [Site]()

    init() {
        initializeSites()
    }

    // MARK: - Init Support

    private func initializeSites() {
        guard let data = HomeWidgetTodayData.read() else {
            sites = []
            return
        }

        sites = data.map { (key: Int, data: HomeWidgetTodayData) -> Site in

            // Note: the image for the site was being set through:
            //
            // icon(from: data)
            //
            // Unfortunately, this had to be turned off for now since images aren't working very well in the
            // customizer as reported here: https://github.com/wordpress-mobile/WordPress-iOS/pull/15397#pullrequestreview-539474644

            let siteDomain: String?

            if let urlComponents = URLComponents(string: data.url),
               let host = urlComponents.host {

                siteDomain = host
            } else {
                siteDomain = nil
            }

            return Site(
                identifier: String(key),
                display: data.siteName,
                subtitle: siteDomain,
                image: nil)
        }.sorted(by: { (firstSite, secondSite) -> Bool in
            let firstTitle = firstSite.displayString.lowercased()
            let secondTitle = secondSite.displayString.lowercased()

            guard firstTitle != secondTitle else {
                let firstSubtitle = firstSite.subtitleString?.lowercased() ?? ""
                let secondSubtitle = secondSite.subtitleString?.lowercased() ?? ""

                return firstSubtitle <= secondSubtitle
            }

            return firstTitle < secondTitle

        })
    }

    // MARK: - Default Site

    private var defaultSiteID: Int? {

        return UserDefaults(suiteName: WPAppGroupName)?.object(forKey: WPStatsHomeWidgetsUserDefaultsSiteIdKey) as? Int
    }

    var defaultSite: Site? {
        guard let defaultSiteID = self.defaultSiteID else {
            return nil
        }

        return sites.first { site in
            return site.identifier == String(defaultSiteID)
        }
    }
}
