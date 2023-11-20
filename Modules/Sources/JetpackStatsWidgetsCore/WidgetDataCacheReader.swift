public protocol WidgetDataCacheReader {
    func widgetData<T: HomeWidgetData>(for siteID: String) -> T?
    func widgetData<T: HomeWidgetData>() -> [T]?
}
