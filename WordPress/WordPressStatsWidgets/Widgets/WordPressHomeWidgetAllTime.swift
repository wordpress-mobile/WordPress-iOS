import WidgetKit
import SwiftUI


struct WordPressHomeWidgetAllTime: Widget {
    private let tracks = Tracks(appGroupName: WPAppGroupName)

    private let placeholderContent = HomeWidgetAllTimeData(siteID: 0,
                                                        siteName: "My WordPress Site",
                                                        url: "",
                                                        timeZone: TimeZone.current,
                                                        date: Date(),
                                                        stats: AllTimeWidgetStats(views: 649,
                                                                                  visitors: 572,
                                                                                  posts: 16,
                                                                                  bestViews: 8))

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: WPHomeWidgetAllTimeKind,
            intent: SelectSiteIntent.self,
            provider: SiteListProvider<HomeWidgetAllTimeData>(service: StatsWidgetsService(), placeholderContent: placeholderContent)
        ) { (entry: StatsWidgetEntry) -> StatsWidgetsView in

            defer {
                tracks.trackWidgetUpdated(widgetKind: WPHomeWidgetAllTimeKind, widgetCountKey: WPHomeWidgetAllTimeProperties)
            }

            return StatsWidgetsView(timelineEntry: entry)
        }
        .configurationDisplayName(LocalizableStrings.allTimeWidgetTitle)
        .description(LocalizableStrings.allTimePreviewDescription)
        .supportedFamilies(FeatureFlag.todayWidget.enabled ? [.systemSmall, .systemMedium] : [])
    }
}
