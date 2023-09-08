// Jetpack Widget configuration

import Foundation

/// - Warning:
/// This configuration extension has a **WordPress** counterpart in the WordPress bundle.
/// Make sure to keep them in sync to avoid build errors when building the WordPress target.
@objc extension AppConfiguration {

    @objc(AppConfigurationWidget)
    class Widget: NSObject {
        @objc(AppConfigurationWidgetStats)
        class Stats: NSObject {
            @objc static let keychainTokenKey = "OAuth2Token"
            @objc static let keychainServiceName = "JetpackTodayWidget"
            @objc static let userDefaultsSiteIdKey = "JetpackHomeWidgetsSiteId"
            @objc static let userDefaultsLoggedInKey = "JetpackHomeWidgetsLoggedIn"
            @objc static let todayKind = "JetpackHomeWidgetToday"
            @objc static let allTimeKind = "JetpackHomeWidgetAllTime"
            @objc static let thisWeekKind = "JetpackHomeWidgetThisWeek"
            @objc static let todayProperties = "JetpackHomeWidgetTodayProperties"
            @objc static let allTimeProperties = "JetpackHomeWidgetAllTimeProperties"
            @objc static let thisWeekProperties = "JetpackHomeWidgetThisWeekProperties"
            @objc static let todayFilename = "JetpackHomeWidgetTodayData.plist"
            @objc static let allTimeFilename = "JetpackHomeWidgetAllTimeData.plist"
            @objc static let thisWeekFilename = "JetpackHomeWidgetThisWeekData.plist"

            /// Lock Screen
            @objc static let lockScreenTodayViewsKind = "JetpackLockScreenWidgetTodayViews"
            @objc static let lockScreenTodayViewsProperties = "JetpackLockScreenWidgetTodayViewsProperties"

            @objc static let lockScreenTodayLikesCommentsKind = "JetpackLockScreenWidgetTodayLikesComments"
            @objc static let lockScreenTodayLikesCommentsProperties = "JetpackLockScreenWidgetTodayLikesCommentsProperties"

            @objc static let lockScreenTodayViewsVisitorsKind = "JetpackLockScreenWidgetTodayViewsVisitors"
            @objc static let lockScreenTodayViewsVisitorsProperties = "JetpackLockScreenWidgetTodayViewsVisitorsProperties"

            @objc static let lockScreenAllTimeViewsKind = "JetpackLockScreenWidgetAllTimeViews"
            @objc static let lockScreenAllTimeViewsProperties = "JetpackLockScreenWidgetAllTimeViewsProperties"

            @objc static let lockScreenAllTimeViewsVisitorsKind = "JetpackLockScreenWidgetAllTimeViewsVisitors"
            @objc static let lockScreenAllTimeViewsVisitorsProperties = "JetpackLockScreenWidgetAllTimeViewsVisitorsProperties"

            @objc static let lockScreenAllTimePostsBestViewsKind = "JetpackLockScreenWidgetAllTimePostsBestViews"
            @objc static let lockScreenAllTimePostsBestViewsProperties = "JetpackLockScreenWidgetAllTimeBestViewsProperties"
        }
    }
}
