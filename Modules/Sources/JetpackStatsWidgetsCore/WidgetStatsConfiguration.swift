import Foundation

public enum WidgetStatsConfiguration {
    public static let keychainTokenKey = "OAuth2Token"
    public static let keychainServiceName = "JetpackTodayWidget"
    public static let userDefaultsSiteIdKey = "JetpackHomeWidgetsSiteId"
    public static let userDefaultsLoggedInKey = "JetpackHomeWidgetsLoggedIn"

    /// The ID of the account's default site, as stored in the shared user defaults by the app.
    public static func defaultSiteID(appGroup: String) -> Int? {
        UserDefaults(suiteName: appGroup)?.object(forKey: userDefaultsSiteIdKey) as? Int
    }
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
            rawValue + "Properties"
        }
    }
}
