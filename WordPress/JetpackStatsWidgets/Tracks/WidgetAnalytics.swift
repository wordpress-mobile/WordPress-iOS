import Foundation
import WidgetKit

@objcMembers class WidgetAnalytics: NSObject {
    static func trackLoadedWidgetsOnApplicationOpened() {
        guard AppConfiguration.isJetpack else { return }

        WidgetCenter.shared.getCurrentConfigurations { result in
            let properties = self.properties(from: result)
            WPAnalytics.track(.widgetsLoadedOnApplicationOpened, properties: properties)
        }
    }

    private static func properties(from widgetInfo: Result<[WidgetInfo], Error>) -> [String: String] {
        guard let installedWidgets = try? widgetInfo.get() else {
            return ["widgets": ""]
        }

        let widgetAnalyticNames: [String] = installedWidgets.map { widgetInfo in
            guard let eventKind = AppConfiguration.Widget.Stats.Kind(rawValue: widgetInfo.kind) else {
                DDLogWarn("⚠️ Make sure the widget: \(widgetInfo.kind), has the correct kind.")
                return "\(widgetInfo.kind)_\(widgetInfo.family)"
            }
            return "\(Events.eventPrefix(for: eventKind))_\(widgetInfo.family)"
        }

        return ["widgets": widgetAnalyticNames.joined(separator: ",")]
    }

    private enum Events: String {
        case homeTodayWidget = "today_home_extension_widget"
        case homeAllTimeWidget = "alltime_home_extension_widget"
        case homeThisWeekWidget = "thisweek_home_extension_widget"
        case lockScreenTodayViewsWidget = "today_views_lockscreen_widget"
        case lockScreenTodayLikesCommentsWidget = "today_likes_comments_lockscreen_widget"
        case lockScreenTodayViewsVisitorsWidget = "today_views_visitors_lockscreen_widget"
        case lockScreenAllTimeViewsWidget = "all_time_views_lockscreen_widget"
        case lockScreenAllTimeViewsVisitorsWidget = "all_time_views_visitors_lockscreen_widget"
        case lockScreenAllTimePostsBestViewsWidget = "all_time_posts_best_views_lockscreen_widget"

        static func eventPrefix(for widgetKind: AppConfiguration.Widget.Stats.Kind) -> Events {
            switch widgetKind {
            case .homeToday:
                return .homeTodayWidget
            case .homeAllTime:
                return .homeAllTimeWidget
            case .homeThisWeek:
                return .homeThisWeekWidget
            case .lockScreenTodayViews:
                return .lockScreenTodayViewsWidget
            case .lockScreenTodayLikesComments:
                 return .lockScreenTodayLikesCommentsWidget
             case .lockScreenTodayViewsVisitors:
                 return .lockScreenTodayViewsVisitorsWidget
             case .lockScreenAllTimeViews:
                 return .lockScreenAllTimeViewsWidget
             case .lockScreenAllTimeViewsVisitors:
                 return .lockScreenAllTimeViewsVisitorsWidget
             case .lockScreenAllTimePostsBestViews:
                 return .lockScreenAllTimePostsBestViewsWidget
            }
        }
    }
}
