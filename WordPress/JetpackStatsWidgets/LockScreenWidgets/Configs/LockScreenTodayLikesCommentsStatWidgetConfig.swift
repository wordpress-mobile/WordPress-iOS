import WidgetKit
import JetpackStatsWidgetsCore

@available(iOS 16.0, *)
struct LockScreenTodayLikesCommentsStatWidgetConfig: LockScreenStatsWidgetConfig {
    typealias WidgetData = HomeWidgetTodayData
    typealias ViewProvider = LockScreenMultiStatWidgetViewProvider<WidgetData>

    var displayName: String {
        LocalizableStrings.todayLikesCommentsWidgetPreviewTitle
    }

    var description: String {
        LocalizableStrings.todayPreviewDescription
    }

    var kind: AppConfiguration.Widget.Stats.Kind {
        AppConfiguration.Widget.Stats.Kind.lockScreenTodayLikesComments
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
            topTitle: LocalizableStrings.likesTitle,
            topValue: \.stats.likes,
            bottomTitle: LocalizableStrings.commentsTitle,
            bottomValue: \.stats.comments
        )
    }
}
