import SwiftUI
import WidgetKit

@main
struct JetpackStatsWidgets: WidgetBundle {
    var body: some Widget {
        HomeWidgetToday()
        HomeWidgetThisWeek()
        HomeWidgetAllTime()
        LockScreenStatsWidget(config: LockScreenTodayViewsStatWidgetConfig())
        LockScreenStatsWidget(config: LockScreenTodayViewsVisitorsStatWidgetConfig())
        LockScreenStatsWidget(config: LockScreenTodayLikesCommentsStatWidgetConfig())
        LockScreenStatsWidget(config: LockScreenAllTimeViewsStatWidgetConfig())
        LockScreenStatsWidget(config: LockScreenAllTimeViewsVisitorsStatWidgetConfig())
        LockScreenStatsWidget(config: LockScreenAllTimePostsBestViewsStatWidgetConfig())
    }
}
