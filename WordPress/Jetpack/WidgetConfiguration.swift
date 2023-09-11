// Jetpack Widget configuration

import Foundation

@objc extension AppConfiguration {
    struct Widget {
        struct Stats {
            static let keychainTokenKey = "OAuth2Token"
            static let keychainServiceName = "JetpackTodayWidget"
            static let userDefaultsSiteIdKey = "JetpackHomeWidgetsSiteId"
            static let userDefaultsLoggedInKey = "JetpackHomeWidgetsLoggedIn"
            static let todayKind = "JetpackHomeWidgetToday"
            static let allTimeKind = "JetpackHomeWidgetAllTime"
            static let thisWeekKind = "JetpackHomeWidgetThisWeek"
            static let todayProperties = "JetpackHomeWidgetTodayProperties"
            static let allTimeProperties = "JetpackHomeWidgetAllTimeProperties"
            static let thisWeekProperties = "JetpackHomeWidgetThisWeekProperties"
            static let todayFilename = "JetpackHomeWidgetTodayData.plist"
            static let allTimeFilename = "JetpackHomeWidgetAllTimeData.plist"
            static let thisWeekFilename = "JetpackHomeWidgetThisWeekData.plist"

            /// Lock Screen
            static let lockScreenTodayViewsKind = "JetpackLockScreenWidgetTodayViews"
            static let lockScreenTodayViewsProperties = "JetpackLockScreenWidgetTodayViewsProperties"

            static let lockScreenTodayLikesCommentsKind = "JetpackLockScreenWidgetTodayLikesComments"
            static let lockScreenTodayLikesCommentsProperties = "JetpackLockScreenWidgetTodayLikesCommentsProperties"

            static let lockScreenTodayViewsVisitorsKind = "JetpackLockScreenWidgetTodayViewsVisitors"
            static let lockScreenTodayViewsVisitorsProperties = "JetpackLockScreenWidgetTodayViewsVisitorsProperties"

            static let lockScreenAllTimeViewsKind = "JetpackLockScreenWidgetAllTimeViews"
            static let lockScreenAllTimeViewsProperties = "JetpackLockScreenWidgetAllTimeViewsProperties"

            static let lockScreenAllTimeViewsVisitorsKind = "JetpackLockScreenWidgetAllTimeViewsVisitors"
            static let lockScreenAllTimeViewsVisitorsProperties = "JetpackLockScreenWidgetAllTimeViewsVisitorsProperties"

            static let lockScreenAllTimePostsBestViewsKind = "JetpackLockScreenWidgetAllTimePostsBestViews"
            static let lockScreenAllTimePostsBestViewsProperties = "JetpackLockScreenWidgetAllTimeBestViewsProperties"
        }
    }
}
