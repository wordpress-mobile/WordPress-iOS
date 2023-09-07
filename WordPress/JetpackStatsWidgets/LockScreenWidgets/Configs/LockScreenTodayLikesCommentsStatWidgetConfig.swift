import WidgetKit

@available(iOS 16.0, *)
struct LockScreenTodayLikesCommentsStatWidgetConfig: LockScreenStatsWidgetConfig {
    typealias WidgetData = HomeWidgetTodayData
    typealias ViewProvider = LockScreenMultiStatWidgetViewProvider<WidgetData>

    var supportFamilies: [WidgetFamily] {
        guard AppConfiguration.isJetpack, FeatureFlag.lockScreenWidget.enabled else {
            return []
        }
        return [.accessoryRectangular]
    }

    var displayName: String {
        LocalizableStrings.todayLikesCommentsWidgetPreviewTitle
    }

    var description: String {
        LocalizableStrings.todayPreviewDescription
    }

    var kind: String {
        AppConfiguration.Widget.Stats.lockScreenTodayLikesCommentsKind
    }

    var countKey: String {
        AppConfiguration.Widget.Stats.lockScreenTodayLikesCommentsProperties
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
