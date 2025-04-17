import WidgetKit
import JetpackStatsWidgetsCore

enum StatsWidgetEntry: TimelineEntry {
    case siteSelected(HomeWidgetData, TimelineProviderContext)
    case loggedOut(StatsWidgetKind)
    case noSite(StatsWidgetKind)
    case noData(StatsWidgetKind)
    case disabled(StatsWidgetKind)

    var date: Date {
        switch self {
        case .siteSelected(let widgetData, _):
            return widgetData.date
        case .loggedOut, .noSite, .noData, .disabled:
            return Date()
        }
    }
}
