import WidgetKit

enum HomeWidgetTodayEntry: TimelineEntry {
    case siteSelected(HomeWidgetTodayData)
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
