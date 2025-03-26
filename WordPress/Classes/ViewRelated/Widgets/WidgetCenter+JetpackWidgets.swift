import Foundation
import WidgetKit
import JetpackStatsWidgetsCore

extension WidgetCenter {
    func reloadTodayTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetStatsConfiguration.Kind.homeToday.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetStatsConfiguration.Kind.lockScreenTodayViews.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetStatsConfiguration.Kind.lockScreenTodayLikesComments.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetStatsConfiguration.Kind.lockScreenTodayViewsVisitors.rawValue)
    }

    func reloadThisWeekTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetStatsConfiguration.Kind.homeThisWeek.rawValue)
    }

    func reloadAllTimeTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetStatsConfiguration.Kind.homeAllTime.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetStatsConfiguration.Kind.lockScreenAllTimeViews.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetStatsConfiguration.Kind.lockScreenAllTimeViewsVisitors.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetStatsConfiguration.Kind.lockScreenAllTimePostsBestViews.rawValue)
    }
}
