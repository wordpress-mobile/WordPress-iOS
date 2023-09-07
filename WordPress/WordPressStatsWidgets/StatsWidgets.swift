import SwiftUI
import WidgetKit

@main
struct WordPressStatsWidgets: WidgetBundle {
    var body: some Widget {
        WordPressHomeWidgetToday()
        WordPressHomeWidgetThisWeek()
        WordPressHomeWidgetAllTime()
        if #available(iOS 16.0, *) {
            LockScreenStatsWidget(config: LockScreenTodayViewsStatWidgetConfig())
            LockScreenStatsWidget(config: LockScreenTodayViewsVisitorsStatWidgetConfig())
            LockScreenStatsWidget(config: LockScreenTodayLikesCommentsStatWidgetConfig())
            LockScreenStatsWidget(config: LockScreenAllTimeViewsStatWidgetConfig())
            LockScreenStatsWidget(config: LockScreenAllTimeViewsVisitorsStatWidgetConfig())
            LockScreenStatsWidget(config: LockScreenAllTimePostsBestViewsStatWidgetConfig())
        }
    }
}
