import SwiftUI
import WidgetKit

@main
struct JetpackStatsWidgets: WidgetBundle {
    var body: some Widget {
        HomeWidgetToday()
        HomeWidgetThisWeek()
        HomeWidgetAllTime()
        if #available(iOS 16.0, *) {
            LockScreenStatsWidget(config: LockScreenTodayViewsStatWidgetConfig())
            LockScreenStatsWidget(config: LockScreenTodayViewsVisitorsStatWidgetConfig())
            LockScreenStatsWidget(config: LockScreenTodayLikesCommentsStatWidgetConfig())
            LockScreenStatsWidget(config: LockScreenThisWeekViewsChartWidgetConfig())
            LockScreenStatsWidget(config: LockScreenAllTimeViewsStatWidgetConfig())
            LockScreenStatsWidget(config: LockScreenAllTimeViewsVisitorsStatWidgetConfig())
            LockScreenStatsWidget(config: LockScreenAllTimePostsBestViewsStatWidgetConfig())
        }
    }
}
