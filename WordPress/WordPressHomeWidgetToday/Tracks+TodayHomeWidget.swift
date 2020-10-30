import Foundation

/// This extension implements helper tracking methods, meant for Today Home Widget usage.
///
extension Tracks {

    // MARK: - Public Methods

    public func trackExtensionStatsLaunched(_ siteID: Int?) {
        let properties = ["site_id": siteID]
        trackExtensionEvent(.statsLaunched, properties: properties as [String: AnyObject]?)
    }

    public func trackExtensionLoginLaunched() {
        trackExtensionEvent(.loginLaunched)
    }

    // MARK: - Private Helpers

    fileprivate func trackExtensionEvent(_ event: ExtensionEvents, properties: [String: AnyObject]? = nil) {
        track(event.rawValue, properties: properties)
    }


    // MARK: - Private Enums

    fileprivate enum ExtensionEvents: String {
        // User taps widget to view Stats in the app
        case statsLaunched  = "wpios_today_home_extension_stats_launched"
        // User taps widget to login to the app
        case loginLaunched  = "wpios_today_home_extension_login_launched"
    }
}
