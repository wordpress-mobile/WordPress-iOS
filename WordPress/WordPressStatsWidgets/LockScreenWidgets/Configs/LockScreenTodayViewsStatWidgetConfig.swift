import WidgetKit

@available(iOS 16.0, *)
struct LockScreenTodayViewsStatWidgetConfig: LockScreenStatsWidgetConfig {
    typealias WidgetData = HomeWidgetTodayData
    typealias ViewProvider = LockScreenSingleStatWidgetViewProvider

    var supportFamilies: [WidgetFamily] {
        guard AppConfiguration.isJetpack, FeatureFlag.lockScreenWidget.enabled else {
            return []
        }
        return [.accessoryRectangular]
    }

    var displayName: String {
        LocalizableStrings.viewsInTodayTitle
    }

    var description: String {
        LocalizableStrings.todayPreviewDescription
    }

    var kind: String {
        AppConfiguration.Widget.Stats.lockScreenTodayViewsKind
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
        LockScreenSingleStatWidgetViewProvider(
            title: LocalizableStrings.viewsInTodayTitle,
            widgetKind: .today
        )
    }
}
