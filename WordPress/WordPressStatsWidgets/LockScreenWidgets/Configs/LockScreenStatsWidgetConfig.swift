import WidgetKit

protocol LockScreenStatsWidgetConfig {
    associatedtype WidgetData: HomeWidgetData & LockScreenStatsWidgetData
    associatedtype ViewProvider: LockScreenStatsWidgetsViewProvider

    var supportFamilies: [WidgetFamily] { get }
    var displayName: String { get }
    var description: String { get }
    var kind: String { get }
    var countKey: String { get }
    var placeholderContent: WidgetData { get }
    var viewProvider: ViewProvider { get }
}
