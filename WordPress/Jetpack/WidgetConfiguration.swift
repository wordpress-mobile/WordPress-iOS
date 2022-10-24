// Jetpack Widget configuration

import Foundation

@objc extension AppConfiguration {

    @objc(AppConfigurationWidget)
    class Widget: NSObject {
        @objc static let statsTodayWidgetKeychainTokenKey = "OAuth2Token"
        @objc static let statsTodayWidgetKeychainServiceName = "JetpackTodayWidget"
        @objc static let statsTodayWidgetUserDefaultsSiteIdKey = "JetpackTodayWidgetSiteId"
        @objc static let statsHomeWidgetsUserDefaultsSiteIdKey = "JetpackHomeWidgetsSiteId"
        @objc static let statsHomeWidgetsUserDefaultsLoggedInKey = "JetpackHomeWidgetsLoggedIn"
        @objc static let statsTodayWidgetUserDefaultsSiteNameKey = "JetpackTodayWidgetSiteName"
        @objc static let statsTodayWidgetUserDefaultsSiteUrlKey = "JetpackTodayWidgetSiteUrl"
        @objc static let statsTodayWidgetUserDefaultsSiteTimeZoneKey = "JetpackTodayWidgetTimeZone"
        @objc static let homeWidgetTodayKind = "JetpackHomeWidgetToday"
        @objc static let homeWidgetAllTimeKind = "JetpackHomeWidgetAllTime"
        @objc static let homeWidgetThisWeekKind = "JetpackHomeWidgetThisWeek"
        @objc static let homeWidgetTodayProperties = "JetpackHomeWidgetTodayProperties"
        @objc static let homeWidgetAllTimeProperties = "JetpackHomeWidgetAllTimeProperties"
        @objc static let homeWidgetThisWeekProperties = "JetpackHomeWidgetThisWeekProperties"
        @objc static let homeWidgetTodayFilename = "JetpackHomeWidgetTodayData.plist"
        @objc static let homeWidgetAllTimeFilename = "JetpackHomeWidgetAllTimeData.plist"
        @objc static let homeWidgetThisWeekFilename = "JetpackHomeWidgetThisWeekData.plist"
        @objc static let newValueOnlyInJetpack = "test"
    }
}
