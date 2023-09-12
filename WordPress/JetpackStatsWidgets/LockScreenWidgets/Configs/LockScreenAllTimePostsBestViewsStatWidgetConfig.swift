import WidgetKit

@available(iOS 16.0, *)
struct LockScreenAllTimePostsBestViewsStatWidgetConfig: LockScreenStatsWidgetConfig {
    typealias WidgetData = HomeWidgetAllTimeData
    typealias ViewProvider = LockScreenMultiStatWidgetViewProvider

    var supportFamilies: [WidgetFamily] {
        guard AppConfiguration.isJetpack, FeatureFlag.lockScreenWidget.enabled else {
            return []
        }
        return [.accessoryRectangular]
    }

    var displayName: String {
        LocalizableStrings.allTimePostMostViewsWidgetPreviewTitle
    }

    var description: String {
        LocalizableStrings.allTimePreviewDescription
    }

    var kind: AppConfiguration.Widget.Stats.Kind {
        AppConfiguration.Widget.Stats.Kind.lockScreenAllTimePostsBestViews
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
            topTitle: LocalizableStrings.postsTitle,
            topValue: \.stats.posts,
            bottomTitle: LocalizableStrings.bestViewsShortTitle,
            bottomValue: \.stats.bestViews
        )
    }
}
