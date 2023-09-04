import Foundation

extension HomeWidgetTodayData: LockScreenStatsWidgetData {
    var views: Int? {
        stats.views
    }

    var comments: Int? {
        stats.comments
    }
}

extension HomeWidgetAllTimeData: LockScreenStatsWidgetData {
    var views: Int? {
        stats.views
    }

    var comments: Int? {
        nil
    }
}

extension HomeWidgetThisWeekData: LockScreenStatsWidgetData {
    var views: Int? {
        nil
    }

    var comments: Int? {
        nil
    }
}
