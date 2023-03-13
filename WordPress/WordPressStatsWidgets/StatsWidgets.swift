import SwiftUI
import WidgetKit

@main
struct WordPressStatsWidgets: WidgetBundle {
    var body: some Widget {
        WordPressHomeWidgetToday()
        WordPressHomeWidgetThisWeek()
        WordPressHomeWidgetAllTime()
#if JETPACK_STATS_WIDGETS
        if #available(iOS 16.0, *) {
            LockScreenStatsWidget()
        }
#endif
    }
}
