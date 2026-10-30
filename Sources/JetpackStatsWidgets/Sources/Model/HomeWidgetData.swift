import Foundation
import JetpackStatsWidgetsCore
import BuildSettingsKit

// MARK: - Local cache

extension HomeWidgetData {

    static func read(from cache: HomeWidgetCache<Self>? = nil) -> [Int: Self]? {
        let cache = cache ?? makeCache()
        do {
            return try cache.read()
        } catch {
            Loggers.widgets.error("HomeWidgetToday: Failed loading data: \(error.localizedDescription)")
            return nil
        }
    }

    static func setItem(item: Self, to cache: HomeWidgetCache<Self>? = nil) {
        let cache = cache ?? makeCache()
        do {
            try cache.setItem(item: item)
        } catch {
            Loggers.widgets.error("HomeWidgetToday: Failed writing data item: \(error.localizedDescription)")
        }
    }

    private static func makeCache() -> HomeWidgetCache<Self> {
        HomeWidgetCache<Self>(fileName: Self.filename, appGroup: BuildSettings.current.appGroupName)
    }
}
