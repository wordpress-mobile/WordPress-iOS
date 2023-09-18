import Foundation

protocol WidgetDataCacheReader {
    func widgetData<T: HomeWidgetData>(for siteID: String) -> T?
    func widgetData<T: HomeWidgetData>() -> [T]?
}

enum WidgetDataReadError: Error {
    case jetpackFeatureDisabled
    case noData
    case noSite
    case loggedOut
}

final class WidgetDataReader<T: HomeWidgetData> {
    let userDefaults: UserDefaults?
    let cacheReader: WidgetDataCacheReader

    init(_ userDefaults: UserDefaults? = UserDefaults(suiteName: WPAppGroupName),
         _ cacheReader: any WidgetDataCacheReader = HomeWidgetDataFileReader()
    ) {
        self.userDefaults = userDefaults
        self.cacheReader = cacheReader
    }

    /// Returns cached widget data based on the selected site when editing widget and the default site.
    /// Configuration.site is nil until IntentHandler is initialized.
    /// Configuration.site can have old value after logging in with a different account. No way to reset configuration when the user logs out.
    /// Using defaultSiteID if both of these cases.
    /// - Parameters:
    ///   - configuration: Configuration of the Widget Site Selection Intent
    ///   - defaultSiteID: ID of the default site in the account
    /// - Returns: Widget data
    func widgetData(
        for configuration: SelectSiteIntent,
        defaultSiteID: Int?
    ) -> Result<T, WidgetDataReadError> {
        guard let defaults = userDefaults else {
            return .failure(.noData)
        }

        if let selectedSite = configuration.site?.identifier,
           let widgetData: T = cacheReader.widgetData(for: selectedSite) {
            return .success(widgetData)
        } else if let defaultSiteID = defaultSiteID,
                  let widgetData: T = cacheReader.widgetData(for: String(defaultSiteID)) {
            return .success(widgetData)
        } else {
            let loggedIn = defaults.bool(forKey: AppConfiguration.Widget.Stats.userDefaultsLoggedInKey)

            if loggedIn {
                /// In rare cases there could be no default site and no defaultSiteId set
                if let firstSiteData: T = cacheReader.widgetData()?.sorted(by: { $0.siteID < $1.siteID }).first {
                    return .success(firstSiteData)
                } else {
                    return .failure(.noSite)
                }
            } else {
                return .failure(.loggedOut)
            }
        }
    }
}
