import Foundation


/// This extension implements helper tracking methods, meant for Today Widget Usage.
///
extension Tracks
{
    // MARK: - Public Methods
    public func trackExtensionAccessed() {
        trackExtensionEvent(.Accessed)
    }

    public func trackExtensionStatsLaunched(siteID: Int) {
        let properties = ["site_id" : siteID]
        trackExtensionEvent(.StatsLaunched, properties: properties)
    }

    public func trackExtensionConfigureLaunched() {
        trackExtensionEvent(.ConfigureLaunched)
    }


    // MARK: - Private Helpers
    private func trackExtensionEvent(event: ExtensionEvents, properties: [String: AnyObject]? = nil) {
        track(event.rawValue, properties: properties)
    }


    // MARK: - Private Enums
    private enum ExtensionEvents : String {
        case Accessed          = "wpios_today_extension_accessed"
        case StatsLaunched     = "wpios_today_extension_stats_launched"
        case ConfigureLaunched = "wpios_today_extension_configure_launched"
    }
}
