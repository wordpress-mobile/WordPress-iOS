import WidgetKit

enum StatsWidgetEntry: TimelineEntry {
    case siteSelected(HomeWidgetData, TimelineProviderContext)
    case loggedOut(StatsWidgetKind)
    case noData
    case disabled

    var date: Date {
        switch self {
        case .siteSelected(let widgetData, _):
            return widgetData.date
        case .loggedOut, .noData, .disabled:
            return Date()
        }
    }
}
