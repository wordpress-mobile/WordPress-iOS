import Foundation

extension HomeWidgetTodayData: LockScreenStatsWidgetData {
    var views: Int? {
        stats.views
    }

    var comments: Int? {
        stats.comments
    }

    var likes: Int? {
        stats.likes
    }
}

extension HomeWidgetAllTimeData: LockScreenStatsWidgetData {
    var views: Int? {
        stats.views
    }

    var comments: Int? {
        nil
    }

    var likes: Int? {
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

    var likes: Int? {
        nil
    }
}
