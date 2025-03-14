import Foundation
import WidgetKit
import JetpackStatsWidgetsCore

struct LockScreenTodayViewsStatWidgetConfig: LockScreenStatsWidgetConfig {
    typealias WidgetData = HomeWidgetTodayData
    typealias ViewProvider = LockScreenSingleStatWidgetViewProvider

    var displayName: String {
        LocalizableStrings.todayViewsWidgetPreviewTitle
    }

    var description: String {
        LocalizableStrings.todayPreviewDescription
    }

    var kind: WidgetStatsConfiguration.Kind {
        WidgetStatsConfiguration.Kind.lockScreenTodayViews
    }

    var placeholderContent: HomeWidgetTodayData {
        HomeWidgetTodayData(
            siteID: 0,
            siteName: "My WordPress Site",
            url: "",
            timeZone: TimeZone.current,
            date: Date(),
            stats: TodayWidgetStats(
                views: 649,
                visitors: 572,
                likes: 16,
                comments: 8
            )
        )
    }

    var viewProvider: ViewProvider<HomeWidgetTodayData> {
        LockScreenSingleStatWidgetViewProvider<HomeWidgetTodayData>(
            title: LocalizableStrings.viewsInTodayTitle,
            value: \.stats.views,
            widgetKind: .today
        )
    }
}
