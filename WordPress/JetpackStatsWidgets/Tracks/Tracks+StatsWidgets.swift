import Foundation
import WidgetKit

/// This extension implements helper tracking methods meant for Home & Lock screen widgets.
///
extension Tracks {

    func trackWidgetUpdatedIfNeeded(entry: LockScreenStatsWidgetEntry<some HomeWidgetData>, widgetKind: AppConfiguration.Widget.Stats.Kind) {
        switch entry {
        case .siteSelected(_, let context):
            if !context.isPreview {
                trackWidgetUpdated(widgetKind: widgetKind)
            }

        case .loggedOut, .noSite, .noData:
            trackWidgetUpdated(widgetKind: widgetKind)
        }
    }

    func trackWidgetUpdatedIfNeeded(entry: StatsWidgetEntry, widgetKind: AppConfiguration.Widget.Stats.Kind) {
        switch entry {
        case .siteSelected(_, let context):
            if !context.isPreview {
                trackWidgetUpdated(widgetKind: widgetKind)
            }

        case .loggedOut, .noSite, .noData, .disabled:
            trackWidgetUpdated(widgetKind: widgetKind)
        }
    }

    func trackWidgetUpdated(widgetKind: AppConfiguration.Widget.Stats.Kind) {

        DispatchQueue.global().async {
            WidgetCenter.shared.getCurrentConfigurations { result in

                switch result {

                case .success(let widgetInfo):
                    let widgetKindInfo = widgetInfo.filter { $0.kind == widgetKind.rawValue }
                    self.trackUpdatedWidgetInfo(widgetInfo: widgetKindInfo, widgetKind: widgetKind)

                case .failure(let error):
                    DDLogError("Home Widget Today error: unable to read widget information. \(error.localizedDescription)")
                }
            }
        }
    }

    private func trackUpdatedWidgetInfo(widgetInfo: [WidgetInfo], widgetKind: AppConfiguration.Widget.Stats.Kind) {
        let widgetPropertiesKey = widgetKind.countKey

        var properties: [String: Int] = [:]

        switch widgetKind {
        case .homeToday, .homeThisWeek, .homeAllTime:
            properties = ["total_widgets": widgetInfo.count,
                          "small_widgets": widgetInfo.filter { $0.family == .systemSmall }.count,
                          "medium_widgets": widgetInfo.filter { $0.family == .systemMedium }.count,
                          "large_widgets": widgetInfo.filter { $0.family == .systemLarge }.count]
        default:
            break
        }

        let previousProperties = UserDefaults(suiteName: WPAppGroupName)?.object(forKey: widgetPropertiesKey) as? [String: Int]

        guard previousProperties != properties else {
            return
        }

        UserDefaults(suiteName: WPAppGroupName)?.set(properties, forKey: widgetPropertiesKey)

        trackExtensionEvent(ExtensionEvents.widgetUpdated(for: widgetKind), properties: properties as [String: AnyObject]?)
    }

    // MARK: - Private Helpers

    fileprivate func trackExtensionEvent(_ event: ExtensionEvents, properties: [String: AnyObject]? = nil) {
        track(event.rawValue, properties: properties)
    }


    // MARK: - Private Enums

    fileprivate enum ExtensionEvents: String {
        // Events when user installs an instance of the widget
        case homeTodayWidgetUpdated = "today_home_extension_widget_updated"
        case homeAllTimeWidgetUpdated = "alltime_home_extension_widget_updated"
        case homeThisWeekWidgetUpdated = "thisweek_home_extension_widget_updated"
        case lockScreenTodayViewsWidgetUpdated = "today_views_lockscreen_widget_updated"
        case lockScreenTodayLikesCommentsWidgetUpdated = "today_likes_comments_lockscreen_widget_updated"
        case lockScreenTodayViewsVisitorsWidgetUpdated = "today_views_visitors_lockscreen_widget_updated"
        case lockScreenAllTimeViewsWidgetUpdated = "all_time_views_lockscreen_widget_updated"
        case lockScreenAllTimeViewsVisitorsWidgetUpdated = "all_time_views_visitors_lockscreen_widget_updated"
        case lockScreenAllTimePostsBestViewsWidgetUpdated = "all_time_posts_best_views_lockscreen_widget_updated"
        case lockScreenThisWeekViewsWidgetUpdated = "this_week_views_lockscreen_widget_updated"

        static func widgetUpdated(for widgetKind: AppConfiguration.Widget.Stats.Kind) -> ExtensionEvents {
            switch widgetKind {
            case .homeToday:
                return .homeTodayWidgetUpdated
            case .homeAllTime:
                return .homeAllTimeWidgetUpdated
            case .homeThisWeek:
                return .homeThisWeekWidgetUpdated
            case .lockScreenTodayViews:
                return .lockScreenTodayViewsWidgetUpdated
            case .lockScreenTodayLikesComments:
                 return .lockScreenTodayLikesCommentsWidgetUpdated
             case .lockScreenTodayViewsVisitors:
                 return .lockScreenTodayViewsVisitorsWidgetUpdated
             case .lockScreenAllTimeViews:
                 return .lockScreenAllTimeViewsWidgetUpdated
             case .lockScreenAllTimeViewsVisitors:
                 return .lockScreenAllTimeViewsVisitorsWidgetUpdated
             case .lockScreenAllTimePostsBestViews:
                 return .lockScreenAllTimePostsBestViewsWidgetUpdated
            case .lockScreenThisWeekViews:
                return .lockScreenThisWeekViewsWidgetUpdated
            }
        }
    }
}
