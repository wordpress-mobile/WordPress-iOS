import WidgetKit
import SwiftUI


struct SiteListProvider<T: HomeWidgetData>: IntentTimelineProvider {

    let service: StatsWidgetsService
    let placeholderContent: T
    let widgetKind: StatsWidgetKind

    // refresh interval of the widget, in minutes
    let refreshInterval = 60
    // minimum elapsed time, in minutes, before new data are fetched from the backend.
    let minElapsedTimeToRefresh = 10

    private var defaultSiteID: Int? {

        UserDefaults(suiteName: WPAppGroupName)?.object(forKey: WPStatsHomeWidgetsUserDefaultsSiteIdKey) as? Int
    }

    private func widgetData(for siteID: String) -> T? {
        /// - TODO: we should not really be needing to do this conversion.  Maybe we can evaluate a better mechanism for site identification.
        guard let siteID = Int(siteID) else {
            return nil
        }

        return T.read()?[siteID]
    }

    func placeholder(in context: Context) -> StatsWidgetEntry {
        StatsWidgetEntry.siteSelected(placeholderContent, context)
    }

    func getSnapshot(for configuration: SelectSiteIntent, in context: Context, completion: @escaping (StatsWidgetEntry) -> Void) {

        guard let site = configuration.site,
              let siteIdentifier = site.identifier,
              let widgetData = widgetData(for: siteIdentifier) else {

            if let siteID = defaultSiteID, let content = T.read()?[siteID] {
                completion(.siteSelected(content, context))
            } else {
                completion(.siteSelected(placeholderContent, context))
            }
            return
        }

        completion(.siteSelected(widgetData, context))
    }

    func getTimeline(for configuration: SelectSiteIntent, in context: Context, completion: @escaping (Timeline<StatsWidgetEntry>) -> Void) {

        guard let site = configuration.site,
              let siteIdentifier = site.identifier,
              let widgetData = widgetData(for: siteIdentifier) else {

            /// - TODO: TODAYWIDGET - This is here because configuration is not updated when the site list changes. It might be a WidgetKit bug. More to come on a separate issue.
            if let siteID = defaultSiteID, let content = T.read()?[siteID] {
                completion(Timeline(entries: [.siteSelected(content, context)], policy: .never))
            } else {
                if let loggedIn = UserDefaults(suiteName: WPAppGroupName)?.bool(forKey: WPStatsHomeWidgetsUserDefaultsLoggedInKey), loggedIn == false {
                    completion(Timeline(entries: [.loggedOut(widgetKind)], policy: .never))
                } else {
                    completion(Timeline(entries: [.noData], policy: .never))
                }
            }
            return
        }

        let date = Date()
        let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: refreshInterval, to: date) ?? date
        let elapsedTime = abs(Calendar.current.dateComponents([.minute], from: widgetData.date, to: date).minute ?? 0)

        let privateCompletion = { (timelineEntry: StatsWidgetEntry) in
            let timeline = Timeline(entries: [timelineEntry], policy: .after(nextRefreshDate))
            completion(timeline)
        }

        // if cached data are "too old", refresh them from the backend, otherwise keep them
        guard elapsedTime > minElapsedTimeToRefresh else {

            privateCompletion(.siteSelected(widgetData, context))
            return
        }

        service.fetchStats(for: widgetData) { result in

            switch result {
            case .failure(let error):
                DDLogError("StatsWidgets: failed to fetch remote stats. Returned error: \(error.localizedDescription)")

                privateCompletion(.siteSelected(widgetData, context))

            case .success(let newWidgetData):

                privateCompletion(.siteSelected(newWidgetData, context))
            }
        }
    }
}


enum StatsWidgetKind {
    case today
    case allTime
    case thisWeek
    case noStats
}
