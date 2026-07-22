#if os(iOS)
import AppIntents
import Foundation

/// A WordPress.com (or Jetpack-connected) site, as exposed to the system via App Intents.
///
/// The identifier is the site's WP.com ID encoded as a decimal string. It deliberately matches
/// the `identifier` of the legacy SiriKit `Site` object so that widget configurations created
/// before the App Intents migration keep resolving to the same site.
///
/// The "ios-widget.ILcGmf" localization key resolves against the app bundle on iOS 26 and
/// the widget extension bundle on iOS 17; see `SelectSiteIntent` for the details.
public struct SiteEntity: AppEntity {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("ios-widget.ILcGmf", defaultValue: "Site")
    )

    public static var defaultQuery: SiteEntityQuery { SiteEntityQuery() }

    public let id: String
    public let name: String
    public let domain: String?

    public var displayRepresentation: DisplayRepresentation {
        if let domain {
            return DisplayRepresentation(title: "\(name)", subtitle: "\(domain)")
        }
        return DisplayRepresentation(title: "\(name)")
    }

    init(siteID: Int, data: HomeWidgetTodayData) {
        self.id = String(siteID)
        self.name = data.siteName
        self.domain = URLComponents(string: data.url)?.host
    }

    /// A placeholder for a configured site that cannot currently be resolved from the
    /// widget cache. Preserving the identifier keeps the user's widget configuration
    /// intact until the cache becomes readable again.
    init(unresolvedID: String) {
        self.id = unresolvedID
        self.name = unresolvedID
        self.domain = nil
    }
}
#endif
