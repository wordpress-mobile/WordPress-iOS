import Foundation

extension HomeWidgetTodayData: LockScreenStatsWidgetData {
    var views: Int? {
        stats.views
    }
}


extension HomeWidgetAllTimeData: LockScreenStatsWidgetData {
    var views: Int? {
        stats.views
    }
}


extension HomeWidgetThisWeekData: LockScreenStatsWidgetData {
    var views: Int? {
        nil
    }
}
