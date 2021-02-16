import WidgetKit

enum StatsWidgetEntry: TimelineEntry {
    case siteSelected(HomeWidgetData)
    case loggedOut(StatsWidgetKind)
    case noData

    var date: Date {
        switch self {
        case .siteSelected(let widgetData):
            return widgetData.date
        case .loggedOut, .noData:
            return Date()
        }
    }
}
