import WidgetKit
import SwiftUI

@available(iOS 16.0, *)
struct LockScreenStatsWidget: Widget {
    private let placeholderContent = HomeWidgetTodayData(
        siteID: 0,
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
            kind: AppConfiguration.Widget.Stats.lockScreenTodayViewsKind,
            intent: SelectSiteIntent.self,
            provider: SiteListProvider<HomeWidgetTodayData>(
                service: StatsWidgetsService(),
                placeholderContent: placeholderContent,
                widgetKind: .today
            )
        ) { (entry: StatsWidgetEntry) -> LockScreenStatsWidgetsView in
            return LockScreenStatsWidgetsView(
                timelineEntry: entry,
                viewProvider: LockScreenSingleStatWidgetViewProvider()
            )
        }
        .configurationDisplayName(LocalizableStrings.todayWidgetTitle)
        .description(LocalizableStrings.todayPreviewDescription)
        .supportedFamilies(supportedFamilies())
    }
}

@available(iOS 16.0, *)
extension LockScreenStatsWidget {
    // TODO: Move to widget config after PR #20317 merged
    func supportedFamilies() -> [WidgetFamily] {
        guard AppConfiguration.isJetpack, FeatureFlag.lockScreenWidget.enabled else {
            return []
        }
        return [.accessoryRectangular]
    }
}
