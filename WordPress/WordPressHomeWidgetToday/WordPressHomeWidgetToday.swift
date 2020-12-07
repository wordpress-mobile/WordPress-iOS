import WidgetKit
import SwiftUI

struct SiteListProvider: IntentTimelineProvider {

    let service = HomeWidgetTodayRemoteService()

    private let tracks = Tracks(appGroupName: WPAppGroupName)

    private var defaultSiteID: Int? {
        // TODO - TODAYWIDGET: taking the default site id from user defaults for now.
        // This would change if the old widget gets reconfigured to a different site than the default.
        // This will be updated with the configuration intent.
        UserDefaults(suiteName: WPAppGroupName)?.object(forKey: WPStatsTodayWidgetUserDefaultsSiteIdKey) as? Int
    }

    private func widgetData(for siteID: String) -> HomeWidgetTodayData? {
        /// - TODO: we should not really be needing to do this conversion.  Maybe we can evaluate a better mechanism for site identification.
        guard let siteID = Int(siteID) else {
            return nil
        }

        return HomeWidgetTodayData.read()?[siteID]
    }

    // TODO - TODAYWIDGET: This can serve as static content to display in the preview if no data are yet available
    // we should define what to put in here
    static let staticContent = HomeWidgetTodayData(siteID: 0,
                                                   siteName: "Places you should visit",
                                                   iconURL: nil,
                                                   url: "",
                                                   timeZone: TimeZone.current,
                                                   date: Date(),
                                                   stats: TodayWidgetStats(views: 5980,
                                                                           visitors: 4208,
                                                                           likes: 107,
                                                                           comments: 5))

    // refresh interval of the widget, in minutes
    static let refreshInterval = 60

    // minimum elapsed time, in minutes, before new data are fetched from the backend.
    static let minElapsedTimeToRefresh = 10

    func placeholder(in context: Context) -> HomeWidgetTodayData {
        Self.staticContent
    }

    func getSnapshot(for configuration: SelectSiteIntent, in context: Context, completion: @escaping (HomeWidgetTodayData) -> Void) {

        guard let site = configuration.site,
              let siteIdentifier = site.identifier,
              let widgetData = widgetData(for: siteIdentifier) else {

            completion(Self.staticContent)
            return
        }

        completion(widgetData)
    }

    func getTimeline(for configuration: SelectSiteIntent, in context: Context, completion: @escaping (Timeline<HomeWidgetTodayData>) -> Void) {

        /// - TODO: review this guard... it's crazy we'd have to ever show static content.  Maybe we need to show an error message?
        ///
        guard let site = configuration.site,
              let siteIdentifier = site.identifier,
              let widgetData = widgetData(for: siteIdentifier) else {

            let timeline = Timeline(entries: [Self.staticContent], policy: .never)
            completion(timeline)
            tracks.trackWidgetUpdated()
            return
        }

        let date = Date()
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: Self.refreshInterval, to: date) ?? date
        let elapsedTime = abs(Calendar.current.dateComponents([.minute], from: widgetData.date, to: date).minute ?? 0)

        let privateCompletion = { (widgetData: HomeWidgetTodayData) in
            let timeline = Timeline(entries: [widgetData], policy: .after(nextRefreshDate))
            completion(timeline)
            tracks.trackWidgetUpdated()
        }

        // if cached data are "too old", refresh them from the backend, otherwise keep them
        guard elapsedTime > Self.minElapsedTimeToRefresh else {

            privateCompletion(widgetData)
            return
        }

        service.fetchStats(for: widgetData) { result in

            switch result {
            case .failure(let error):
                DDLogError("HomeWidgetToday: failed to fetch remote stats. Returned error: \(error.localizedDescription)")

                privateCompletion(widgetData)
            case .success(let widgetData):

                DispatchQueue.global().async {
                    // update the item in the local cache
                    HomeWidgetTodayData.setItem(item: widgetData)
                }

                privateCompletion(widgetData)
            }
        }
    }
}


@main
struct WordPressHomeWidgetToday: Widget {

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: WPHomeWidgetTodayKind,
            intent: SelectSiteIntent.self,
            provider: SiteListProvider()
        ) { entry in
            TodayWidgetView(content: entry)
        }
        .configurationDisplayName("Today")
        .description("Stay up to date with today's activity on your WordPress site.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
