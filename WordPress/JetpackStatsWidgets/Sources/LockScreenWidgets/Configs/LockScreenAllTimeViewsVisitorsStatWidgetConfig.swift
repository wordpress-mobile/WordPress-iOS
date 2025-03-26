import WidgetKit
import JetpackStatsWidgetsCore

struct LockScreenAllTimeViewsVisitorsStatWidgetConfig: LockScreenStatsWidgetConfig {
    typealias WidgetData = HomeWidgetAllTimeData
    typealias ViewProvider = LockScreenMultiStatWidgetViewProvider

    var displayName: String {
        LocalizableStrings.allTimeViewsVisitorsWidgetPreviewTitle
    }

    var description: String {
        LocalizableStrings.allTimePreviewDescription
    }

    var kind: WidgetStatsConfiguration.Kind {
        WidgetStatsConfiguration.Kind.lockScreenAllTimeViewsVisitors
    }

    var placeholderContent: HomeWidgetAllTimeData {
        HomeWidgetAllTimeData(
            siteID: 0,
            siteName: "My WordPress Site",
            url: "",
            timeZone: TimeZone.current,
            date: Date(),
            stats: AllTimeWidgetStats(
                views: 649,
                visitors: 572,
                posts: 5,
                bestViews: 10
            )
        )
    }

    var viewProvider: ViewProvider<HomeWidgetAllTimeData> {
        LockScreenMultiStatWidgetViewProvider<HomeWidgetAllTimeData>(
            widgetKind: .allTime,
            topTitle: LocalizableStrings.viewsTitle,
            topValue: \.stats.views,
            bottomTitle: LocalizableStrings.visitorsTitle,
            bottomValue: \.stats.visitors
        )
    }
}
