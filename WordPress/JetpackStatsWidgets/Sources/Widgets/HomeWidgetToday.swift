import Foundation
import WidgetKit
import SwiftUI
import JetpackStatsWidgetsCore
import TracksMini

struct HomeWidgetToday: Widget {
    private let tracks = Tracks()

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
            kind: WidgetStatsConfiguration.Kind.homeToday.rawValue,
            intent: SelectSiteIntent.self,
            provider: SiteListProvider<HomeWidgetTodayData>(service: StatsWidgetsService(),
                                                            placeholderContent: placeholderContent,
                                                            widgetKind: .today)
        ) { (entry: StatsWidgetEntry) -> StatsWidgetsView in
            return StatsWidgetsView(timelineEntry: entry)
        }
        .configurationDisplayName(LocalizableStrings.todayWidgetTitle)
        .description(LocalizableStrings.todayPreviewDescription)
        .supportedFamilies([.systemSmall, .systemMedium])
        .iOS17ContentMarginsDisabled() /// Temporarily disable additional iOS17 margins for widgets for StandBy
    }
}
