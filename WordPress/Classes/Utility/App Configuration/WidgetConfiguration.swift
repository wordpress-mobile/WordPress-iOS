// WordPress Widget configuration

import Foundation

/// - Warning:
/// This configuration extension has a **Jetpack** counterpart in the Jetpack bundle.
/// Make sure to keep them in sync to avoid build errors when building the Jetpack target.
@objc extension AppConfiguration {

    @objc(AppConfigurationWidget)
    class Widget: NSObject {
        @objc(AppConfigurationWidgetStats)
        class Stats: NSObject {
            @objc static let keychainTokenKey = "OAuth2Token"
            @objc static let keychainServiceName = "TodayWidget"
            @objc static let userDefaultsSiteIdKey = "WordPressHomeWidgetsSiteId"
            @objc static let userDefaultsLoggedInKey = "WordPressHomeWidgetsLoggedIn"
            @objc static let userDefaultsJetpackFeaturesDisabledKey = "WordPressJPFeaturesDisabledKey"
            @objc static let todayKind = "WordPressHomeWidgetToday"
            @objc static let allTimeKind = "WordPressHomeWidgetAllTime"
            @objc static let thisWeekKind = "WordPressHomeWidgetThisWeek"
            @objc static let todayProperties = "WordPressHomeWidgetTodayProperties"
            @objc static let allTimeProperties = "WordPressHomeWidgetAllTimeProperties"
            @objc static let thisWeekProperties = "WordPressHomeWidgetThisWeekProperties"
            @objc static let todayFilename = "HomeWidgetTodayData.plist"
            @objc static let allTimeFilename = "HomeWidgetAllTimeData.plist"
            @objc static let thisWeekFilename = "HomeWidgetThisWeekData.plist"

            /// Lock Screen
            @objc static let lockScreenTodayViewsKind = "WordPressLockScreenWidgetTodayViews"
            @objc static let lockScreenTodayViewsProperties = "WordPressLockScreenWidgetTodayViewsProperties"

            @objc static let lockScreenTodayLikesCommentsKind = "WordPressLockScreenWidgetTodayLikesComments"
            @objc static let lockScreenTodayLikesCommentsProperties = "WordPressLockScreenWidgetTodayLikesCommentsProperties"

            @objc static let lockScreenTodayViewsVisitorsKind = "WordPressLockScreenWidgetTodayViewsVisitors"
            @objc static let lockScreenTodayViewsVisitorsProperties = "WordPressLockScreenWidgetTodayViewsVisitorsProperties"

            @objc static let lockScreenAllTimeViewsKind = "WordPressLockScreenWidgetAllTimeViews"
            @objc static let lockScreenAllTimeViewsProperties = "WordPressLockScreenWidgetAllTimeViewsProperties"

            @objc static let lockScreenAllTimeViewsVisitorsKind = "WordPressLockScreenWidgetAllTimeViewsVisitors"
            @objc static let lockScreenAllTimeViewsVisitorsProperties = "WordPressLockScreenWidgetAllTimeViewsVisitorsProperties"

            @objc static let lockScreenAllTimePostsBestViewsKind = "WordPressLockScreenWidgetAllTimePostsBestViews"
            @objc static let lockScreenAllTimePostsBestViewsProperties = "WordPressLockScreenWidgetAllTimeBestViewsProperties"
        }

        // iOS13 Stats Today Widgets
        @objc(AppConfigurationWidgetStatsToday)
        class StatsToday: NSObject {
            @objc static let userDefaultsSiteIdKey = "WordPressTodayWidgetSiteId"
            @objc static let userDefaultsSiteNameKey = "WordPressTodayWidgetSiteName"
            @objc static let userDefaultsSiteUrlKey = "WordPressTodayWidgetSiteUrl"
            @objc static let userDefaultsSiteTimeZoneKey = "WordPressTodayWidgetTimeZone"
            @objc static let todayFilename = "TodayData.plist"
            @objc static let thisWeekFilename = "ThisWeekData.plist"
            @objc static let allTimeFilename = "AllTimeData.plist"
        }
    }
}
