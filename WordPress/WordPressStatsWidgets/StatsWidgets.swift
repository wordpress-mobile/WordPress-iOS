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
        }
    }
}
