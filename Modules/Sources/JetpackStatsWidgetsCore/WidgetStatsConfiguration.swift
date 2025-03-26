import Foundation

public enum WidgetStatsConfiguration {
    public static let keychainTokenKey = "OAuth2Token"
    public static let keychainServiceName = "JetpackTodayWidget"
    public static let userDefaultsSiteIdKey = "JetpackHomeWidgetsSiteId"
    public static let userDefaultsLoggedInKey = "JetpackHomeWidgetsLoggedIn"
    public static let todayFilename = "JetpackHomeWidgetTodayData.plist"
    public static let allTimeFilename = "JetpackHomeWidgetAllTimeData.plist"
    public static let thisWeekFilename = "JetpackHomeWidgetThisWeekData.plist"

    public enum Kind: String {
        case homeToday = "JetpackHomeWidgetToday"
        case homeAllTime = "JetpackHomeWidgetAllTime"
        case homeThisWeek = "JetpackHomeWidgetThisWeek"
        case lockScreenTodayViews = "JetpackLockScreenWidgetTodayViews"
        case lockScreenTodayLikesComments = "JetpackLockScreenWidgetTodayLikesComments"
        case lockScreenTodayViewsVisitors = "JetpackLockScreenWidgetTodayViewsVisitors"
        case lockScreenAllTimeViews = "JetpackLockScreenWidgetAllTimeViews"
        case lockScreenAllTimeViewsVisitors = "JetpackLockScreenWidgetAllTimeViewsVisitors"
        case lockScreenAllTimePostsBestViews = "JetpackLockScreenWidgetAllTimePostsBestViews"

        public var countKey: String {
            return rawValue + "Properties"
        }
    }
}
