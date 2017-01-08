import Foundation


/// This extension implements helper tracking methods, meant for Today Widget Usage.
///
extension Tracks {
    // MARK: - Public Methods
    public func trackExtensionAccessed() {
        trackExtensionEvent(.Accessed)
    }

    public func trackExtensionStatsLaunched(_ siteID: Int) {
        let properties = ["site_id": siteID]
        trackExtensionEvent(.StatsLaunched, properties: properties as [String : AnyObject]?)
    }

    public func trackExtensionConfigureLaunched() {
        trackExtensionEvent(.ConfigureLaunched)
    }


    // MARK: - Private Helpers
    fileprivate func trackExtensionEvent(_ event: ExtensionEvents, properties: [String: AnyObject]? = nil) {
        track(event.rawValue, properties: properties)
    }


    // MARK: - Private Enums
    fileprivate enum ExtensionEvents: String {
        case Accessed          = "wpios_today_extension_accessed"
        case StatsLaunched     = "wpios_today_extension_stats_launched"
        case ConfigureLaunched = "wpios_today_extension_configure_launched"
    }
}
