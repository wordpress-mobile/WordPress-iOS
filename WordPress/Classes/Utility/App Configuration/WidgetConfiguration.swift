// WordPress Widget configuration

import Foundation

/// - Warning:
/// This configuration extension has a **Jetpack** counterpart in the Jetpack bundle.
/// Make sure to keep them in sync to avoid build errors when builing the Jetpack target.
@objc extension AppConfiguration {

    @objc(AppConfigurationWidget)
    class Widget: NSObject {
        @objc(AppConfigurationWidgetStats)
        class Stats: NSObject {
            @objc static let keychainTokenKey = "OAuth2Token"
            @objc static let keychainServiceName = "TodayWidget"
            @objc static let userDefaultsSiteIdKey = "WordPressHomeWidgetsSiteId"
            @objc static let userDefaultsLoggedInKey = "WordPressHomeWidgetsLoggedIn"
            @objc static let userDefaultsJetpackFeaturesEnabledKey = "WordPressJPFeaturesEnabledKey"
            @objc static let todayKind = "WordPressHomeWidgetToday"
            @objc static let allTimeKind = "WordPressHomeWidgetAllTime"
            @objc static let thisWeekKind = "WordPressHomeWidgetThisWeek"
            @objc static let todayProperties = "WordPressHomeWidgetTodayProperties"
            @objc static let allTimeProperties = "WordPressHomeWidgetAllTimeProperties"
            @objc static let thisWeekProperties = "WordPressHomeWidgetThisWeekProperties"
            @objc static let todayFilename = "HomeWidgetTodayData.plist"
            @objc static let allTimeFilename = "HomeWidgetAllTimeData.plist"
            @objc static let thisWeekFilename = "HomeWidgetThisWeekData.plist"
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
