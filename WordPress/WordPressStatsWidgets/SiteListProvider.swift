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
        guard let defaultSiteID = defaultSiteID else {
            let loggedIn = UserDefaults(suiteName: WPAppGroupName)?.bool(forKey: WPStatsHomeWidgetsUserDefaultsLoggedInKey) ?? false
            if loggedIn {
                completion(Timeline(entries: [.noSite], policy: .never))
            } else {
                completion(Timeline(entries: [.loggedOut(widgetKind)], policy: .never))
            }
            return
        }


        guard let widgetData = widgetData(for: configuration, defaultSiteID: defaultSiteID) else {
            completion(Timeline(entries: [.noData], policy: .never))
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

// MARK: - Widget Data

private extension SiteListProvider {
    /// Returns cached widget data based on the selected site when editing widget and the default site.
    /// Configuration.site is nil until IntentHandler is initialized.
    /// Configuration.site can have old value after logging in with a different account. No way to reset configuration when the user logs out.
    /// Using defaultSiteID if both of these cases.
    /// - Parameters:
    ///   - configuration: Configuration of the Widget Site Selection Intent
    ///   - defaultSiteID: ID of the default site in the account
    /// - Returns: Widget data
    func widgetData(for configuration: SelectSiteIntent, defaultSiteID: Int) -> T? {

        /// If configuration.site.identifier has value but there's no widgetData, it means that this identifier comes from previously logged in account
        return widgetData(for: configuration.site?.identifier ?? String(defaultSiteID))
            ?? widgetData(for: String(defaultSiteID))
    }

    func widgetData(for siteID: String) -> T? {
        /// - TODO: we should not really be needing to do this conversion.  Maybe we can evaluate a better mechanism for site identification.
        guard let siteID = Int(siteID) else {
            return nil
        }

        return T.read()?[siteID]
    }
}

enum StatsWidgetKind {
    case today
    case allTime
    case thisWeek
    case noSite
    case noStats
}
