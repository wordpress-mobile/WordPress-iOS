import BuildSettingsKit
import CocoaLumberjackSwift
import Foundation
import JetpackStatsWidgetsCore
import WidgetKit

struct SiteListProvider<T: HomeWidgetData>: AppIntentTimelineProvider {

    let service: StatsWidgetsService
    let placeholderContent: T
    let widgetKind: StatsWidgetKind

    // refresh interval of the widget, in minutes
    let refreshInterval = 30
    // minimum elapsed time, in minutes, before new data are fetched from the backend.
    let minElapsedTimeToRefresh = 1

    private var defaultSiteID: Int? {
        WidgetStatsConfiguration.defaultSiteID(appGroup: BuildSettings.current.appGroupName)
    }

    private let widgetDataLoader = WidgetDataReader<T>()

    func placeholder(in context: Context) -> StatsWidgetEntry {
        StatsWidgetEntry.siteSelected(placeholderContent, context)
    }

    func snapshot(for configuration: SelectSiteIntent, in context: Context) async -> StatsWidgetEntry {
        switch widgetDataLoader.widgetData(for: configuration, defaultSiteID: defaultSiteID) {
        case .success(let widgetData):
            return .siteSelected(widgetData, context)
        case .failure:
            return .siteSelected(placeholderContent, context)
        }
    }

    func timeline(for configuration: SelectSiteIntent, in context: Context) async -> Timeline<StatsWidgetEntry> {
        switch widgetDataLoader.widgetData(for: configuration, defaultSiteID: defaultSiteID) {
        case .success(let widgetData):
            let date = Date()
            let nextRefreshDate = Calendar.current.date(byAdding: .minute, value: refreshInterval, to: date) ?? date
            let elapsedTime = abs(
                Calendar.current.dateComponents([.minute], from: widgetData.date, to: date).minute ?? 0
            )

            // if cached data are "too old", refresh them from the backend, otherwise keep them
            guard elapsedTime > minElapsedTimeToRefresh else {
                return Timeline(entries: [.siteSelected(widgetData, context)], policy: .after(nextRefreshDate))
            }

            let entry: StatsWidgetEntry
            do {
                let newWidgetData = try await service.fetchStats(for: widgetData)
                entry = .siteSelected(newWidgetData, context)
            } catch {
                DDLogError(
                    "StatsWidgets: failed to fetch remote stats. Returned error: \(error.localizedDescription)"
                )
                entry = .siteSelected(widgetData, context)
            }
            return Timeline(entries: [entry], policy: .after(nextRefreshDate))
        case .failure(let error):
            switch error {
            case .noData:
                return Timeline(entries: [.noData(widgetKind)], policy: .never)
            case .noSite:
                return Timeline(entries: [.noSite(widgetKind)], policy: .never)
            case .loggedOut:
                return Timeline(entries: [.loggedOut(widgetKind)], policy: .never)
            case .jetpackFeatureDisabled:
                return Timeline(entries: [.disabled(widgetKind)], policy: .never)
            }
        }
    }
}

enum StatsWidgetKind {
    case today
    case allTime
    case thisWeek
}
