import WidgetKit
import SwiftUI


struct WordPressHomeWidgetToday: Widget {
    private let tracks = Tracks(appGroupName: WPAppGroupName)

    private let placeholderContent = HomeWidgetTodayData(siteID: 0,
                                                        siteName: "My WordPress Site",
                                                        url: "",
                                                        timeZone: TimeZone.current,
                                                        date: Date(),
                                                        stats: TodayWidgetStats(views: 649,
                                                                                visitors: 572,
                                                                                likes: 16,
                                                                                comments: 8))

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: WPHomeWidgetTodayKind,
            intent: SelectSiteIntent.self,
            provider: SiteListProvider<HomeWidgetTodayData>(service: StatsWidgetsService(),
                                                            placeholderContent: placeholderContent,
                                                            widgetKind: .today)
        ) { (entry: StatsWidgetEntry) -> StatsWidgetsView in

            defer {
                tracks.trackWidgetUpdatedIfNeeded(entry: entry,
                                                  widgetKind: WPHomeWidgetTodayKind,
                                                  widgetCountKey: WPHomeWidgetTodayProperties)
            }

            return StatsWidgetsView(timelineEntry: entry)
        }
        .configurationDisplayName(LocalizableStrings.todayWidgetTitle)
        .description(LocalizableStrings.todayPreviewDescription)
        .supportedFamilies(FeatureFlag.todayWidget.enabled ? [.systemSmall, .systemMedium] : [])
    }
}
