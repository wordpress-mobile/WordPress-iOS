import Foundation
import WidgetKit

extension WidgetCenter {
    func reloadTodayTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.Kind.homeToday.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.Kind.lockScreenTodayViews.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.Kind.lockScreenTodayLikesComments.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.Kind.lockScreenTodayViewsVisitors.rawValue)
    }

    func reloadThisWeekTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.Kind.homeThisWeek.rawValue)
    }

    func reloadAllTimeTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.Kind.homeAllTime.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.Kind.lockScreenAllTimeViews.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.Kind.lockScreenAllTimeViewsVisitors.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.Kind.lockScreenAllTimePostsBestViews.rawValue)
    }
}
