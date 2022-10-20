// WordPress Widget configuration

import Foundation

@objc extension AppConfiguration {

    @objc(AppConfigurationWidget)
    class Widget: NSObject {
        @objc static let statsTodayWidgetKeychainTokenKey = "OAuth2Token"
        @objc static let statsTodayWidgetKeychainServiceName = "TodayWidget"
        @objc static let statsTodayWidgetUserDefaultsSiteIdKey = "WordPressTodayWidgetSiteId"
        @objc static let statsHomeWidgetsUserDefaultsSiteIdKey = "WordPressHomeWidgetsSiteId"
        @objc static let statsHomeWidgetsUserDefaultsLoggedInKey = "WordPressHomeWidgetsLoggedIn"
        @objc static let statsTodayWidgetUserDefaultsSiteNameKey = "WordPressTodayWidgetSiteName"
        @objc static let statsTodayWidgetUserDefaultsSiteUrlKey = "WordPressTodayWidgetSiteUrl"
        @objc static let statsTodayWidgetUserDefaultsSiteTimeZoneKey = "WordPressTodayWidgetTimeZone"
        @objc static let homeWidgetTodayKind = "WordPressHomeWidgetToday"
        @objc static let homeWidgetAllTimeKind = "WordPressHomeWidgetAllTime"
        @objc static let homeWidgetThisWeekKind = "WordPressHomeWidgetThisWeek"
        @objc static let homeWidgetTodayProperties = "WordPressHomeWidgetTodayProperties"
        @objc static let homeWidgetAllTimeProperties = "WordPressHomeWidgetAllTimeProperties"
        @objc static let homeWidgetThisWeekProperties = "WordPressHomeWidgetThisWeekProperties"
        @objc static let homeWidgetTodayFilename = "HomeWidgetTodayData.plist"
        @objc static let homeWidgetAllTimeFilename = "HomeWidgetAllTimeData.plist"
        @objc static let homeWidgetThisWeekFilename = "HomeWidgetThisWeekData.plist"

        // iOS13 Widgets
        @objc static let todayWidgetTodayFilename = "TodayData.plist"
        @objc static let todayWidgetThisWeekFilename = "ThisWeekData.plist"
        @objc static let todayWidgetAllTimeFilename = "AllTimeData.plist"
    }
}
