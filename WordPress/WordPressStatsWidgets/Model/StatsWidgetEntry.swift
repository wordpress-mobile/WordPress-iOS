import WidgetKit

enum StatsWidgetEntry: TimelineEntry {
    case siteSelected(HomeWidgetData)
    case loggedOut

    var date: Date {
        switch self {
        case .siteSelected(let widgetData):
            return widgetData.date
        case .loggedOut:
            return Date()
        }
    }
}
