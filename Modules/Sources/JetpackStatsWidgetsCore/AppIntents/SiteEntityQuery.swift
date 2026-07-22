#if os(iOS)
import AppIntents
import BuildSettingsKit
import Foundation

/// Resolves `SiteEntity` values from the widget data cache in the app group container.
///
/// The site list mirrors what the stats widgets can display: the sites written by the app
/// into the Today widget's cache.
///
/// The query deliberately provides no `defaultResult()`: a widget whose site parameter is
/// nil follows the app's current default site dynamically (resolved by `WidgetDataReader`
/// on every reload), matching the legacy SiriKit behavior. A default result would be baked
/// into the configuration at widget-add time and pin the widget to that site forever.
public struct SiteEntityQuery: EntityQuery {
    private let appGroup: String

    public init() {
        self.init(appGroup: BuildSettings.current.appGroupName)
    }

    init(appGroup: String) {
        self.appGroup = appGroup
    }

    public func entities(for identifiers: [SiteEntity.ID]) async throws -> [SiteEntity] {
        let sites = cachedSites()
        // A configured widget re-resolves its site through this method on every reload.
        // An identifier missing from the cache (deleted mid-write, decode failure) must
        // stay attached to the configuration, or the widget silently falls back to the
        // default site. Keep unknown identifiers as placeholder entities.
        return identifiers.map { identifier in
            sites.first { $0.id == identifier } ?? SiteEntity(unresolvedID: identifier)
        }
    }

    public func suggestedEntities() async throws -> [SiteEntity] {
        cachedSites()
    }

    private func cachedSites() -> [SiteEntity] {
        guard let items = try? HomeWidgetCache<HomeWidgetTodayData>(appGroup: appGroup).read() else {
            return []
        }
        return
            items
            .map { SiteEntity(siteID: $0.key, data: $0.value) }
            .sorted { lhs, rhs in
                let lhsName = lhs.name.lowercased()
                let rhsName = rhs.name.lowercased()
                guard lhsName != rhsName else {
                    return (lhs.domain?.lowercased() ?? "") < (rhs.domain?.lowercased() ?? "")
                }
                return lhsName < rhsName
            }
    }
}
#endif
