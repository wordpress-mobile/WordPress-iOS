import WidgetKit
import SwiftUI


struct WordPressHomeWidgetToday: Widget {
    private let tracks = Tracks(appGroupName: WPAppGroupName)

    private let placeholderContent = HomeWidgetTodayData(siteID: 0,
                                                        siteName: "My WordPress Site",
                                                        iconURL: nil,
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
            provider: SiteListProvider<HomeWidgetTodayData>(service: StatsWidgetsService(), placeholderContent: placeholderContent)
        ) { (entry: StatsWidgetEntry) -> TodayWidgetView in

            defer {
                tracks.trackWidgetUpdated()
            }

            return TodayWidgetView(timelineEntry: entry)
        }
        .configurationDisplayName(LocalizableStrings.widgetTitle)
        .description(LocalizableStrings.previewDescription)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
