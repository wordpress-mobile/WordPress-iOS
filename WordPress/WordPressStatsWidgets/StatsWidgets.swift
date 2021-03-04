import SwiftUI
import WidgetKit

@main
struct WordPressStatsWidgets: WidgetBundle {
    var body: some Widget {
        WordPressHomeWidgetToday()
        WordPressHomeWidgetThisWeek()
        WordPressHomeWidgetAllTime()
    }
}
