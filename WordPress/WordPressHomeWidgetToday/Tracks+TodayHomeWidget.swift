import Foundation
import WidgetKit

/// This extension implements helper tracking methods, meant for Today Home Widget usage.
///
extension Tracks {

    // MARK: - Public Methods

    public func trackExtensionStatsLaunched(_ siteID: Int) {
        let properties = ["site_id": siteID]
        trackExtensionEvent(.statsLaunched, properties: properties as [String: AnyObject]?)
    }

    public func trackExtensionLoginLaunched() {
        trackExtensionEvent(.loginLaunched)
    }

    public func trackWidgetInstalled(widgetInfo: [WidgetInfo]) {
        var properties = [String: AnyObject]()
        widgetInfo.enumerated().forEach {
            properties["kind - \($0.offset)"] = $0.element.kind as AnyObject
            properties["family - \($0.offset)"] = $0.element.family as AnyObject
            //properties["id - \($0.offset)"] = $0.element.id as AnyObject
            properties["siteID - \($0.offset)"] = "Null" as AnyObject

            if let siteIntent = $0.element.configuration as? SelectSiteIntent, let site = siteIntent.site, let siteID = site.identifier {
                properties["siteID - \($0.offset)"] = siteID as AnyObject
            }
        }
        let widgetCount = ["widget_count": widgetInfo.count]
        trackExtensionEvent(.widgetInstalled, properties: widgetCount as [String: AnyObject]?)
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
        // User installs an instance of the widget
        case widgetInstalled = "wpios_today_home_extension_widget_installed"
    }
}
