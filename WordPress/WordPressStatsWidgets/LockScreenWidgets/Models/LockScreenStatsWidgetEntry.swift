import WidgetKit

enum LockScreenStatsWidgetEntry: TimelineEntry {
    case siteSelected(LockScreenStatsWidgetData, TimelineProviderContext)
    case loggedOut
    case noSite
    case noData

    var date: Date {
        switch self {
        case .siteSelected(let widgetData, _):
            return widgetData.date
        case .loggedOut, .noSite, .noData:
            return Date()
        }
    }
}
