import Foundation
import WidgetKit

/// This extension implements helper tracking methods meant for Home & Lock screen widgets.
///
extension Tracks {

    func trackWidgetUpdatedIfNeeded(entry: LockScreenStatsWidgetEntry<some HomeWidgetData>, widgetKind: String, widgetCountKey: String) {
        switch entry {
        case .siteSelected(_, let context):
            if !context.isPreview {
                trackWidgetUpdated(widgetKind: widgetKind,
                                   widgetCountKey: widgetCountKey)
            }

        case .loggedOut, .noSite, .noData:
            trackWidgetUpdated(widgetKind: widgetKind,
                               widgetCountKey: widgetCountKey)
        }
    }

    func trackWidgetUpdatedIfNeeded(entry: StatsWidgetEntry, widgetKind: String, widgetCountKey: String) {
        switch entry {
        case .siteSelected(_, let context):
            if !context.isPreview {
                trackWidgetUpdated(widgetKind: widgetKind,
                                   widgetCountKey: widgetCountKey)
            }

        case .loggedOut, .noSite, .noData, .disabled:
            trackWidgetUpdated(widgetKind: widgetKind,
                               widgetCountKey: widgetCountKey)
        }
    }

    func trackWidgetUpdated(widgetKind: String, widgetCountKey: String) {

        DispatchQueue.global().async {
            WidgetCenter.shared.getCurrentConfigurations { result in

                switch result {

                case .success(let widgetInfo):
                    let widgetKindInfo = widgetInfo.filter { $0.kind == widgetKind }
                    self.trackUpdatedWidgetInfo(widgetInfo: widgetKindInfo, widgetPropertiesKey: widgetCountKey)

                case .failure(let error):
                    DDLogError("Home Widget Today error: unable to read widget information. \(error.localizedDescription)")
                }
            }
        }
    }

    private func trackUpdatedWidgetInfo(widgetInfo: [WidgetInfo], widgetPropertiesKey: String) {

        var properties = ["total_widgets": widgetInfo.count,
                          "small_widgets": widgetInfo.filter { $0.family == .systemSmall }.count,
                          "medium_widgets": widgetInfo.filter { $0.family == .systemMedium }.count,
                          "large_widgets": widgetInfo.filter { $0.family == .systemLarge }.count]
        if #available(iOS 16.0, *) {
            properties["rectangular_widgets"] = widgetInfo.filter { $0.family == .accessoryRectangular }.count
        }

        let previousProperties = UserDefaults(suiteName: WPAppGroupName)?.object(forKey: widgetPropertiesKey) as? [String: Int]

        guard previousProperties != properties else {
            return
        }

        UserDefaults(suiteName: WPAppGroupName)?.set(properties, forKey: widgetPropertiesKey)

        trackExtensionEvent(ExtensionEvents.widgetUpdated(for: widgetPropertiesKey), properties: properties as [String: AnyObject]?)
    }

    // MARK: - Private Helpers

    fileprivate func trackExtensionEvent(_ event: ExtensionEvents, properties: [String: AnyObject]? = nil) {
        track(event.rawValue, properties: properties)
    }


    // MARK: - Private Enums

    fileprivate enum ExtensionEvents: String {
        // User installs an instance of the today widget
        case todayWidgetUpdated = "today_home_extension_widget_updated"
        // User installs an instance of the all time widget
        case allTimeWidgetUpdated = "alltime_home_extension_widget_updated"
        // Users installs an instance of the this week widget
        case thisWeekWidgetUpdated = "thisweek_home_extension_widget_updated"
        // Users installs an instance of the lockscreen today views widget
        case todayViewsLockScreenWidgetUpdated = "today_views_lockscreen_extension_widget_updated"

        case noEvent

        static func widgetUpdated(for key: String) -> ExtensionEvents {
            switch key {
            case AppConfiguration.Widget.Stats.todayProperties:
                return .todayWidgetUpdated
            case AppConfiguration.Widget.Stats.allTimeProperties:
                return .allTimeWidgetUpdated
            case AppConfiguration.Widget.Stats.thisWeekProperties:
                return .thisWeekWidgetUpdated
            case AppConfiguration.Widget.Stats.lockScreenTodayViewsProperties:
                return .todayViewsLockScreenWidgetUpdated
            default:
                return .noEvent
            }
        }
    }
}
