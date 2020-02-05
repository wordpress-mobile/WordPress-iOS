import Foundation


/// This extension implements helper tracking methods, meant for Today Widget Usage.
///
extension Tracks {

    // MARK: - Public Methods

    public func trackExtensionStatsLaunched(_ siteID: Int) {
        let properties = ["site_id": siteID]
        trackExtensionEvent(.statsLaunched, properties: properties as [String: AnyObject]?)
    }

    public func trackExtensionConfigureLaunched() {
        trackExtensionEvent(.configureLaunched)
    }

    public func trackDisplayModeChanged(properties: [String: Bool]) {
        trackExtensionEvent(.displayModeChanged, properties: properties as [String: AnyObject])
    }

    // MARK: - Private Helpers

    fileprivate func trackExtensionEvent(_ event: ExtensionEvents, properties: [String: AnyObject]? = nil) {
        track(event.rawValue, properties: properties)
    }


    // MARK: - Private Enums

    fileprivate enum ExtensionEvents: String {
        case statsLaunched      = "wpios_all_time_extension_stats_launched"
        case configureLaunched  = "wpios_all_time_extension_configure_launched"
        case displayModeChanged = "wpios_all_time_extension_display_mode_changed"
    }
}
