import Foundation
import JetpackStatsWidgetsCore

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

        return cacheReader.widgetData(
            forSiteIdentifier: configuration.site?.identifier,
            defaultSiteID: defaultSiteID,
            userLoggedIn: defaults.bool(forKey: AppConfiguration.Widget.Stats.userDefaultsLoggedInKey)
        )
    }
}
