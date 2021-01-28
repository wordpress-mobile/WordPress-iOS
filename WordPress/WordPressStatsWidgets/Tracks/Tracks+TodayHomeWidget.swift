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

    public func trackWidgetUpdated() {

        DispatchQueue.global().async {
            WidgetCenter.shared.getCurrentConfigurations { result in

                switch result {

                case .success(let widgetInfo):
                    self.trackUpdatedWidgetInfo(widgetInfo: widgetInfo)

                case .failure(let error):
                    DDLogError("Home Widget Today error: unable to read widget information. \(error.localizedDescription)")
                }
            }
        }
    }

    private func trackUpdatedWidgetInfo(widgetInfo: [WidgetInfo]) {
        /// - TODO: TODAYWIDGET - This might need to change depending on wether or not we use one extension for multiple widgets

        let previousCount = UserDefaults(suiteName: WPAppGroupName)?.object(forKey: WPHomeWidgetTodayCount) as? Int ?? 0
        let newCount = widgetInfo.count

        guard previousCount != newCount else {
            return
        }

        UserDefaults(suiteName: WPAppGroupName)?.set(newCount, forKey: WPHomeWidgetTodayCount)

        let properties = ["total_widgets": newCount,
                          "small_widgets": widgetInfo.filter { $0.family == .systemSmall }.count,
                          "medium_widgets": widgetInfo.filter { $0.family == .systemMedium }.count,
                          "large_widgets": widgetInfo.filter { $0.family == .systemLarge }.count]

        trackExtensionEvent(.widgetUpdated, properties: properties as [String: AnyObject]?)
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
        case widgetUpdated = "wpios_today_home_extension_widget_updated"
    }
}
