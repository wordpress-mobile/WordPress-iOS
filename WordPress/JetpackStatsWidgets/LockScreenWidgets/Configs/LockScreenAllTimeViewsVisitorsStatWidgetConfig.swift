import WidgetKit

@available(iOS 16.0, *)
struct LockScreenAllTimeViewsVisitorsStatWidgetConfig: LockScreenStatsWidgetConfig {
    typealias WidgetData = HomeWidgetAllTimeData
    typealias ViewProvider = LockScreenMultiStatWidgetViewProvider

    var supportFamilies: [WidgetFamily] {
        guard AppConfiguration.isJetpack, FeatureFlag.lockScreenWidget.enabled else {
            return []
        }
        return [.accessoryRectangular]
    }

    var displayName: String {
        LocalizableStrings.allTimeViewsVisitorsWidgetPreviewTitle
    }

    var description: String {
        LocalizableStrings.allTimePreviewDescription
    }

    var kind: String {
        AppConfiguration.Widget.Stats.Kind.lockScreenAllTimeViewsVisitors.rawValue
    }

    var countKey: String {
        AppConfiguration.Widget.Stats.Kind.lockScreenAllTimeViewsVisitors.countKey
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
