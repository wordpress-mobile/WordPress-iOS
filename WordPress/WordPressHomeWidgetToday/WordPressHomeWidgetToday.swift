import WidgetKit
import SwiftUI

struct SiteListProvider: IntentTimelineProvider {

    let service = HomeWidgetTodayRemoteService()

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
    static let placeholderContent = HomeWidgetTodayData(siteID: 0,
                                                        siteName: "My WordPress Site",
                                                        iconURL: nil,
                                                        url: "",
                                                        timeZone: TimeZone.current,
                                                        date: Date(),
                                                        stats: TodayWidgetStats(views: 649,
                                                                                visitors: 572,
                                                                                likes: 16,
                                                                                comments: 8))

    // refresh interval of the widget, in minutes
    static let refreshInterval = 5

    // minimum elapsed time, in minutes, before new data are fetched from the backend.
    static let minElapsedTimeToRefresh = 10

    func placeholder(in context: Context) -> HomeWidgetTodayEntry {
        HomeWidgetTodayEntry.siteSelected(Self.placeholderContent)
    }

    func getSnapshot(for configuration: SelectSiteIntent, in context: Context, completion: @escaping (HomeWidgetTodayEntry) -> Void) {

        guard let site = configuration.site,
              let siteIdentifier = site.identifier,
              let widgetData = widgetData(for: siteIdentifier) else {

            if let siteID = defaultSiteID, let content = HomeWidgetTodayData.read()?[siteID] {
                completion(.siteSelected(content))
            } else {
                completion(.siteSelected(Self.placeholderContent))
            }
            return
        }

        completion(.siteSelected(widgetData))
    }

    func getTimeline(for configuration: SelectSiteIntent, in context: Context, completion: @escaping (Timeline<HomeWidgetTodayEntry>) -> Void) {

        /// - TODO: review this guard... it's crazy we'd have to ever show static content.  Maybe we need to show an error message?
        ///
        guard let site = configuration.site,
              let siteIdentifier = site.identifier,
              let widgetData = widgetData(for: siteIdentifier) else {

            /// - TODO: TODAYWIDGET - This is here because configuration is not updated when the site list changes. It might be a WidgetKit bug. More to come on a separate issue.
            if let siteID = defaultSiteID, let content = HomeWidgetTodayData.read()?[siteID] {
                completion(Timeline(entries: [.siteSelected(content)], policy: .never))
            } else {
                completion(Timeline(entries: [.loggedOut], policy: .never))
            }
            return
        }

        let date = Date()
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: Self.refreshInterval, to: date) ?? date
        let elapsedTime = abs(Calendar.current.dateComponents([.minute], from: widgetData.date, to: date).minute ?? 0)

        let privateCompletion = { (timelineEntry: HomeWidgetTodayEntry) in
            let timeline = Timeline(entries: [timelineEntry], policy: .after(nextRefreshDate))
            completion(timeline)
        }

        // if cached data are "too old", refresh them from the backend, otherwise keep them
        guard elapsedTime > Self.minElapsedTimeToRefresh else {

            privateCompletion(.siteSelected(widgetData))
            return
        }

        service.fetchStats(for: widgetData) { result in

            switch result {
            case .failure(let error):
                DDLogError("HomeWidgetToday: failed to fetch remote stats. Returned error: \(error.localizedDescription)")

                privateCompletion(.siteSelected(widgetData))
            case .success(let widgetData):

                DispatchQueue.global().async {
                    // update the item in the local cache
                    HomeWidgetTodayData.setItem(item: widgetData)
                }

                privateCompletion(.siteSelected(widgetData))
            }
        }
    }
}


@main
struct WordPressHomeWidgetToday: Widget {
    private let tracks = Tracks(appGroupName: WPAppGroupName)

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: WPHomeWidgetTodayKind,
            intent: SelectSiteIntent.self,
            provider: SiteListProvider()
        ) { (entry: HomeWidgetTodayEntry) -> TodayWidgetView in

            defer {
                tracks.trackWidgetUpdated()
            }

            return TodayWidgetView(timelineEntry: entry)
        }
        .configurationDisplayName("Today")
        .description("Stay up to date with today's activity on your WordPress site.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
