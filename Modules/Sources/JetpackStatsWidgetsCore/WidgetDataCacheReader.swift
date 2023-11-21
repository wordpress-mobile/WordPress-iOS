public protocol WidgetDataCacheReader {
    func widgetData<T: HomeWidgetData>(for siteID: String) -> T?
    func widgetData<T: HomeWidgetData>() -> [T]?
}

public extension WidgetDataCacheReader {

    func widgetData(
        forSiteIdentifier identifier: String?,
        defaultSiteID: Int?,
        userLoggedIn: Bool
    ) -> Result<T, WidgetDataReadError> {
        if let selectedSite = identifier, let widgetData: T = widgetData(for: selectedSite) {
            return .success(widgetData)
        } else if let defaultSiteID, let widgetData: T = widgetData(for: String(defaultSiteID)) {
            return .success(widgetData)
        } else {
            if userLoggedIn {
                /// In rare cases there could be no default site and no defaultSiteId set
                if let firstSiteData: T = widgetData()?.sorted(by: { $0.siteID < $1.siteID }).first {
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
