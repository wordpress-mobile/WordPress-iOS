import Foundation

final class HomeWidgetDataFileReader: WidgetDataCacheReader {
    func widgetData<T: HomeWidgetData>(for siteID: String) -> T? {
        /// - TODO: we should not really be needing to do this conversion.  Maybe we can evaluate a better mechanism for site identification.
        guard let siteID = Int(siteID) else {
            return nil
        }

        return T.read()?[siteID]
    }

    func widgetData<T: HomeWidgetData>() -> [T]? {
        return T.read()?.map { $0.value }
    }
}
