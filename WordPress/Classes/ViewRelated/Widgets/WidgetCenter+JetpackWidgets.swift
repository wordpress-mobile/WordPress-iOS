import Foundation
import WidgetKit

extension WidgetCenter {
    func reloadTodayTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.todayKind)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.lockScreenTodayViewsKind)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.lockScreenTodayLikesCommentsKind)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.lockScreenTodayViewsVisitorsKind)
    }

    func reloadThisWeekTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.thisWeekKind)
    }

    func reloadAllTimeTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.allTimeKind)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.lockScreenAllTimeViewsKind)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.lockScreenAllTimeViewsVisitorsKind)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.Widget.Stats.lockScreenAllTimePostsBestViewsKind)
    }
}
