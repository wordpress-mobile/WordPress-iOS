import WidgetKit
import SwiftUI


struct WordPressHomeWidgetThisWeek: Widget {
    private let tracks = Tracks(appGroupName: WPAppGroupName)

    static let secondsPerDay = 86400.0

    private let placeholderContent = HomeWidgetThisWeekData(siteID: 0,
                                                            siteName: "My WordPress Site",
                                                            url: "",
                                                            timeZone: TimeZone.current,
                                                            date: Date(),
                                                            stats: ThisWeekWidgetStats(days: [ThisWeekWidgetDay(date: Date(),
                                                                                                                viewsCount: 130,
                                                                                                                dailyChangePercent: -0.22),
                                                                                              ThisWeekWidgetDay(date: Date(timeIntervalSinceNow: -Self.secondsPerDay),
                                                                                                                viewsCount: 250,
                                                                                                                dailyChangePercent: -0.06),
                                                                                              ThisWeekWidgetDay(date: Date(timeIntervalSinceNow: -(Self.secondsPerDay * 2)),
                                                                                                                viewsCount: 260,
                                                                                                                dailyChangePercent: 0.86),
                                                                                              ThisWeekWidgetDay(date: Date(timeIntervalSinceNow: -(Self.secondsPerDay * 3)),
                                                                                                                viewsCount: 140,
                                                                                                                dailyChangePercent: -0.3),
                                                                                              ThisWeekWidgetDay(date: Date(timeIntervalSinceNow: -(Self.secondsPerDay * 4)),
                                                                                                                viewsCount: 200,
                                                                                                                dailyChangePercent: -0.46),
                                                                                              ThisWeekWidgetDay(date: Date(timeIntervalSinceNow: -(Self.secondsPerDay * 5)),
                                                                                                                viewsCount: 370,
                                                                                                                dailyChangePercent: 0.19),
                                                                                              ThisWeekWidgetDay(date: Date(timeIntervalSinceNow: -(Self.secondsPerDay * 6)),
                                                                                                                viewsCount: 310,
                                                                                                                dailyChangePercent: 0.07)]))

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: WPHomeWidgetThisWeekKind,
            intent: SelectSiteIntent.self,
            provider: SiteListProvider<HomeWidgetThisWeekData>(service: StatsWidgetsService(),
                                                               placeholderContent: placeholderContent,
                                                               widgetKind: .thisWeek)
        ) { (entry: StatsWidgetEntry) -> StatsWidgetsView in

            defer {
                tracks.trackWidgetUpdatedIfNeeded(entry: entry,
                                                  widgetKind: WPHomeWidgetThisWeekKind,
                                                  widgetCountKey: WPHomeWidgetThisWeekProperties)
            }

            return StatsWidgetsView(timelineEntry: entry)
        }
        .configurationDisplayName(LocalizableStrings.thisWeekWidgetTitle)
        .description(LocalizableStrings.thisWeekPreviewDescription)
        .supportedFamilies(FeatureFlag.todayWidget.enabled ? [.systemMedium, .systemLarge] : [])
    }
}
