import WidgetKit

@available(iOS 16.0, *)
struct LockScreenThisWeekViewsChartWidgetConfig: LockScreenStatsWidgetConfig {
    typealias WidgetData = HomeWidgetThisWeekData
    typealias ViewProvider = LockScreenChartWidgetViewProvider

    var displayName: String {
        LocalizableStrings.viewsThisWeekTitle
    }

    var description: String {
        LocalizableStrings.thisWeekPreviewDescription
    }

    var kind: AppConfiguration.Widget.Stats.Kind {
        AppConfiguration.Widget.Stats.Kind.lockScreenThisWeekViews
    }

    var placeholderContent: HomeWidgetThisWeekData {
        let secondsPerDay = 86400.0
        return HomeWidgetThisWeekData(
            siteID: 0,
            siteName: "My WordPress Site",
            url: "",
            timeZone: TimeZone.current,
            date: Date(),
            stats: ThisWeekWidgetStats(
                days: Array<Int>(0...13).map {
                    ThisWeekWidgetDay(
                        date: Date(timeIntervalSinceNow: -secondsPerDay * Double($0)),
                        viewsCount: Int.random(in: 150...300),
                        dailyChangePercent: 0
                    )
                }
            )
        )
    }

    var viewProvider: ViewProvider<HomeWidgetThisWeekData> {
        LockScreenChartWidgetViewProvider<HomeWidgetThisWeekData>(
            title: LocalizableStrings.viewsThisWeekTitle,
            value: \.stats.days,
            widgetKind: .thisWeek
        )
    }
}
