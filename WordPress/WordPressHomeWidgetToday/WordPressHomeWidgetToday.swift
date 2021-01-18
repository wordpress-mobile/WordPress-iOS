import WidgetKit
import SwiftUI


struct WordPressHomeWidgetToday: Widget {
    private let tracks = Tracks(appGroupName: WPAppGroupName)

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: WPHomeWidgetTodayKind,
            intent: SelectSiteIntent.self,
            provider: SiteListProvider(service: HomeWidgetTodayRemoteService())
        ) { (entry: HomeWidgetTodayEntry) -> TodayWidgetView in

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
