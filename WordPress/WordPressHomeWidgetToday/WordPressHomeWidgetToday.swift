import WidgetKit
import SwiftUI

// TODO - TODAYWIDGET: remove this static model when real data come in.
let staticModel = TodayWidgetContent(siteTitle: "Places you should visit",
                                     stats:TodayWidgetStats(views: 5980,
                                                            visitors: 4208,
                                                            likes: 107,
                                                            comments: 5))

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> TodayWidgetContent {
        staticModel
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayWidgetContent) -> ()) {
        completion(staticModel)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // TODO - TODAYWIDGET: Using the "old widget" configuration, for now.
        guard let initialStats = TodayWidgetStats.loadSavedData() else {
            return
        }

        let entries = [TodayWidgetContent(siteTitle: siteName, stats: initialStats)]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    // TODO - TODAYWIDGET: Using the "old widget" configuration, for now.
    var siteName: String {
        UserDefaults(suiteName: WPAppGroupName)?.string(forKey: WPStatsTodayWidgetUserDefaultsSiteNameKey) ?? "Site name not found"
    }

}


@main
struct WordPressHomeWidgetToday: Widget {
    private let kind: String = "WordPressHomeWidgetToday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodayWidgetView(content: entry)
        }
        .configurationDisplayName("Today")
        .description("Stay up to date with today's activity on your WordPress site.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
