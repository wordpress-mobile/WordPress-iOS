import WidgetKit

enum HomeWidgetTodayEntry: TimelineEntry {
    case siteSelected(HomeWidgetTodayData)
    case loggedOut
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
