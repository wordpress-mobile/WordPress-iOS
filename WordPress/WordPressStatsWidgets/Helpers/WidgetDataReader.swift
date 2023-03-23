import Foundation

final class WidgetDataReader<T: HomeWidgetData> {
    /// Returns cached widget data based on the selected site when editing widget and the default site.
    /// Configuration.site is nil until IntentHandler is initialized.
    /// Configuration.site can have old value after logging in with a different account. No way to reset configuration when the user logs out.
    /// Using defaultSiteID if both of these cases.
    /// - Parameters:
    ///   - configuration: Configuration of the Widget Site Selection Intent
    ///   - defaultSiteID: ID of the default site in the account
    /// - Returns: Widget data
    func widgetData(for configuration: SelectSiteIntent, defaultSiteID: Int?) -> T? {

        /// If configuration.site.identifier has value but there's no widgetData, it means that this identifier comes from previously logged in account
        if let selectedSite = configuration.site?.identifier, let widgetData = widgetData(for: selectedSite) {
            return widgetData
        } else if let defaultSiteID = defaultSiteID {
            return widgetData(for: String(defaultSiteID))
        } else {
            return nil
        }
    }

    private func widgetData(for siteID: String) -> T? {
        /// - TODO: we should not really be needing to do this conversion.  Maybe we can evaluate a better mechanism for site identification.
        guard let siteID = Int(siteID) else {
            return nil
        }

        return T.read()?[siteID]
    }
}
