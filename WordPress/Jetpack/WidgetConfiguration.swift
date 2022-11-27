// Jetpack Widget configuration

import Foundation

/// - Warning:
/// This configuartion extension has a **WordPress** counterpart in the WordPress bundle.
/// Make sure to keep them in sync to avoid build errors when builing the WordPress target.
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
        }


        // iOS13 Stats Today Widgets
        @objc(AppConfigurationWidgetStatsToday)
        class StatsToday: NSObject {
            @objc static let userDefaultsSiteIdKey = "JetpackTodayWidgetSiteId"
            @objc static let userDefaultsSiteNameKey = "JetpackTodayWidgetSiteName"
            @objc static let userDefaultsSiteUrlKey = "JetpackTodayWidgetSiteUrl"
            @objc static let userDefaultsSiteTimeZoneKey = "JetpackTodayWidgetTimeZone"
            @objc static let todayFilename = "JetpackTodayData.plist"
            @objc static let thisWeekFilename = "JetpackThisWeekData.plist"
            @objc static let allTimeFilename = "JetpackAllTimeData.plist"
        }
    }
}
