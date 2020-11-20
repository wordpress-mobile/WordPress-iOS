import WidgetKit
import SwiftUI


struct Provider: TimelineProvider {
    // TODO - TODAYWIDGET: Kept these methods simple on purpose, for now.
    // They might complicate depending on Context
    func placeholder(in context: Context) -> HomeWidgetTodayData {
        Constants.staticContent
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeWidgetTodayData) -> ()) {
        getSnapshotData(completion: completion)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        getTimelineData(completion: completion)
    }
}

// MARK: - Widget data
private extension Provider {

    func getSnapshotData(completion: @escaping (HomeWidgetTodayData) -> ()) {

        completion(widgetData ?? Constants.staticContent)
    }

    func getTimelineData(completion: @escaping (Timeline<Entry>) -> ()) {

        let date = Date()
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: Constants.refreshInterval, to: date) ?? date

        let entry = widgetData ?? Constants.staticContent

        let timeline = Timeline(entries: [entry], policy: .after(nextRefreshDate))
        completion(timeline)
    }

    private var defaultSiteID: Int? {
        // TODO - TODAYWIDGET: taking the default site id from user defaults for now.
        // This would change if the old widget gets reconfigured to a different site than the default.
        // This will be updated with the configuration intent.
        UserDefaults(suiteName: WPAppGroupName)?.object(forKey: WPStatsTodayWidgetUserDefaultsSiteIdKey) as? Int
    }

    private var widgetData: HomeWidgetTodayData? {
        // TODO - TODAYWIDGET: we might change this, but for now an ID equal to zero should not return any valid data
        HomeWidgetTodayData.read()?[defaultSiteID ?? 0]
    }
}

// MARK: - Constants
private extension Provider {
    enum Constants {
        // TODO - TODAYWIDGET: This can serve as static content to display in the preview if no data are yet available
        // we should define what to put in here
        static let staticContent = HomeWidgetTodayData(siteID: 0,
                                                       siteName: "Places you should visit",
                                                       url: "",
                                                       timeZone: TimeZone.current,
                                                       date: Date(),
                                                       stats: TodayWidgetStats(views: 5980,
                                                                               visitors: 4208,
                                                                               likes: 107,
                                                                               comments: 5))
        // refresh interval of the widget, in minutes
        static let refreshInterval = 60
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
