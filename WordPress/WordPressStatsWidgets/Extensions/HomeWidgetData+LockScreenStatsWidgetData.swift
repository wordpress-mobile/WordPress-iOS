import Foundation

extension HomeWidgetTodayData: LockScreenStatsWidgetData {
    var views: Int? {
        stats.views
    }

    var widgetURL: URL? {
        URL(string: HomeWidgetTodayData.statsUrl + "\(siteID)?source=lockscreen_widget")
    }
}

extension HomeWidgetAllTimeData: LockScreenStatsWidgetData {
    var views: Int? {
        stats.views
    }

    var widgetURL: URL? {
        URL(string: HomeWidgetAllTimeData.statsUrl + "\(siteID)?source=lockscreen_widget")
    }
}

extension HomeWidgetThisWeekData: LockScreenStatsWidgetData {
    var views: Int? {
        nil
    }

    var widgetURL: URL? {
        URL(string: HomeWidgetThisWeekData.statsUrl + "\(siteID)?source=lockscreen_widget")
    }
}
