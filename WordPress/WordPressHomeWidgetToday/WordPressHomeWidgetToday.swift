import WidgetKit
import SwiftUI


struct Provider: TimelineProvider {
    // TODO - TODAYWIDGET: Kept these methods simple on purpose, for now.
    // They might complicate depending on Context
    func placeholder(in context: Context) -> TodayWidgetContent {
        Constants.staticContent
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayWidgetContent) -> ()) {
        getSnapshotData(completion: completion)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        getTimelineData(completion: completion)
    }
}

// MARK: - Widget data
private extension Provider {

    // TODO - TODAYWIDGET: Using the "old widget" configuration, for now.
    var siteName: String {
        let defaults = UserDefaults(suiteName: WPAppGroupName)

        if let title = defaults?.string(forKey: WPStatsTodayWidgetUserDefaultsSiteNameKey),
           !title.isEmpty {
            return title
        }

        if let url = defaults?.string(forKey: WPStatsTodayWidgetUserDefaultsSiteUrlKey),
                  !url.isEmpty {
            return url
        }
        return "Site not found"
    }

    func getSnapshotData(completion: @escaping (TodayWidgetContent) -> ()) {
        // TODO - TODAYWIDGET: Using the "old widget" configuration, for now.
        guard let initialStats = TodayWidgetStats.loadSavedData() else {
            completion(Constants.staticContent)
            return
        }
        completion(TodayWidgetContent(date: Date(), siteTitle: siteName, stats: initialStats))
    }

    func getTimelineData(completion: @escaping (Timeline<Entry>) -> ()) {

        let date = Date()
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: Constants.refreshInterval, to: date)
        // TODO - TODAYWIDGET: This is just a sample data set to test timeline updates
        let randomNumber = Int.random(in: 4 ... 100)
        let entries = [TodayWidgetContent(date: date,
                                          siteTitle: "My Site + \(randomNumber)",
                                          stats: TodayWidgetStats(views: randomNumber,
                                                                  visitors: randomNumber,
                                                                  likes: randomNumber,
                                                                  comments: randomNumber))]

        let timeline = Timeline(entries: entries, policy: .after(nextRefreshDate!))
        completion(timeline)
    }
}

// MARK: - Constants
private extension Provider {
    enum Constants {
        // TODO - TODAYWIDGET: This can serve as static content to display in the preview if no data are yet available
        // we should define what to put in here
        static let staticContent = TodayWidgetContent(date: Date(),
                                                      siteTitle: "Places you should visit",
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
