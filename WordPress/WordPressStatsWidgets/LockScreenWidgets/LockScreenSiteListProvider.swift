import WidgetKit
import SwiftUI

struct LockScreenSiteListProvider<T: HomeWidgetData & LockScreenStatsWidgetData>: IntentTimelineProvider {
    let service: StatsWidgetsService
    let placeholderContent: T

    // refresh interval of the widget, in minutes
    let refreshInterval = 30
    // minimum elapsed time, in minutes, before new data are fetched from the backend.
    let minElapsedTimeToRefresh = 1

    private var defaultSiteID: Int? {
        UserDefaults(suiteName: WPAppGroupName)?.object(forKey: AppConfiguration.Widget.Stats.userDefaultsSiteIdKey) as? Int
    }

    private let widgetDataLoader = WidgetDataReader<T>()

    func placeholder(in context: Context) -> LockScreenStatsWidgetEntry {
        LockScreenStatsWidgetEntry.siteSelected(placeholderContent, context)
    }

    func getSnapshot(for configuration: SelectSiteIntent, in context: Context, completion: @escaping (LockScreenStatsWidgetEntry) -> Void) {
        let content = widgetDataLoader.widgetData(for: configuration, defaultSiteID: defaultSiteID) ?? placeholderContent
        completion(.siteSelected(content, context))
    }

    func getTimeline(for configuration: SelectSiteIntent, in context: Context, completion: @escaping (Timeline<LockScreenStatsWidgetEntry>) -> Void) {
        switch widgetDataLoader.widgetData(
            for: configuration,
            defaultSiteID: defaultSiteID,
            isJetpack: AppConfiguration.isJetpack
        ) {
        case .success(let widgetData):
            let date = Date()
            let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: refreshInterval, to: date) ?? date
            let elapsedTime = abs(Calendar.current.dateComponents([.minute], from: widgetData.date, to: date).minute ?? 0)

            let privateCompletion = { (timelineEntry: LockScreenStatsWidgetEntry) in
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
                    DDLogError("LockScreen StatsWidgets: failed to fetch remote stats. Returned error: \(error.localizedDescription)")
                    privateCompletion(.siteSelected(widgetData, context))
                case .success(let newWidgetData):
                    privateCompletion(.siteSelected(newWidgetData, context))
                }
            }
        case .failure(let error):
            switch error {
            case .noData:
                completion(Timeline(entries: [.noData], policy: .never))
            case .noSite:
                completion(Timeline(entries: [.noSite], policy: .never))
            case .loggedOut:
                completion(Timeline(entries: [.loggedOut], policy: .never))
            case .jetpackFeatureDisabled:
                DDLogError("LockScreen StatsWidgets: lock screen widget should have Jetpack feature disable error")
                completion(Timeline(entries: [.noData], policy: .never))
            }
        }
    }
}
