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
