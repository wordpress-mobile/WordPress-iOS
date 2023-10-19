// Jetpack Widget configuration

import Foundation

@objc extension AppConfiguration {
    struct Widget {
        struct Stats {
            static let keychainTokenKey = "OAuth2Token"
            static let keychainServiceName = "JetpackTodayWidget"
            static let userDefaultsSiteIdKey = "JetpackHomeWidgetsSiteId"
            static let userDefaultsLoggedInKey = "JetpackHomeWidgetsLoggedIn"
            static let todayFilename = "JetpackHomeWidgetTodayData.plist"
            static let allTimeFilename = "JetpackHomeWidgetAllTimeData.plist"
            static let thisWeekFilename = "JetpackHomeWidgetThisWeekData.plist"

            enum Kind: String {
                case homeToday = "JetpackHomeWidgetToday"
                case homeAllTime = "JetpackHomeWidgetAllTime"
                case homeThisWeek = "JetpackHomeWidgetThisWeek"
                case lockScreenTodayViews = "JetpackLockScreenWidgetTodayViews"
                case lockScreenTodayLikesComments = "JetpackLockScreenWidgetTodayLikesComments"
                case lockScreenTodayViewsVisitors = "JetpackLockScreenWidgetTodayViewsVisitors"
                case lockScreenAllTimeViews = "JetpackLockScreenWidgetAllTimeViews"
                case lockScreenAllTimeViewsVisitors = "JetpackLockScreenWidgetAllTimeViewsVisitors"
                case lockScreenAllTimePostsBestViews = "JetpackLockScreenWidgetAllTimePostsBestViews"
                case lockScreenThisWeekViews = "JetpackLockScreenWidgetThisWeekViews"

                var countKey: String {
                    return rawValue + "Properties"
                }
            }
        }
    }
}
