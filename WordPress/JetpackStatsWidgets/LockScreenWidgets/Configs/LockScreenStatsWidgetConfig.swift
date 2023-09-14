import WidgetKit

protocol LockScreenStatsWidgetConfig {
    associatedtype WidgetData: HomeWidgetData
    associatedtype ViewProvider: LockScreenStatsWidgetsViewProvider<WidgetData>

    var supportFamilies: [WidgetFamily] { get }
    var displayName: String { get }
    var description: String { get }
    var kind: AppConfiguration.Widget.Stats.Kind { get }
    var placeholderContent: WidgetData { get }
    var viewProvider: ViewProvider { get }
}

extension LockScreenStatsWidgetConfig {
    var supportFamilies: [WidgetFamily] {
        if #available(iOSApplicationExtension 16.0, *) {
            return [.accessoryRectangular]
        } else {
            return []
        }
    }
}
