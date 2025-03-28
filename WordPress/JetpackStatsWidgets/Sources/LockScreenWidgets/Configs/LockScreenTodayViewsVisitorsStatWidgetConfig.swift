import Foundation
import WidgetKit
import JetpackStatsWidgetsCore

struct LockScreenTodayViewsVisitorsStatWidgetConfig: LockScreenStatsWidgetConfig {
    typealias WidgetData = HomeWidgetTodayData
    typealias ViewProvider = LockScreenMultiStatWidgetViewProvider<WidgetData>

    var displayName: String {
        LocalizableStrings.todayViewsVisitorsWidgetPreviewTitle
    }

    var description: String {
        LocalizableStrings.todayPreviewDescription
    }

    var kind: WidgetStatsConfiguration.Kind {
        WidgetStatsConfiguration.Kind.lockScreenTodayViewsVisitors
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

    var viewProvider: ViewProvider {
        LockScreenMultiStatWidgetViewProvider(
            widgetKind: .today,
            topTitle: LocalizableStrings.viewsTitle,
            topValue: \.stats.views,
            bottomTitle: LocalizableStrings.visitorsTitle,
            bottomValue: \.stats.visitors
        )
    }
}
