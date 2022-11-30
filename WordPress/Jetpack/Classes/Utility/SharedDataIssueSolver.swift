@objcMembers
final class SharedDataIssueSolver: NSObject {

    private let contextManager: CoreDataStack
    private let keychainUtils: KeychainUtils
    private let sharedDefaults: UserPersistentRepository?
    private let localFileStore: LocalFileStore

    init(contextManager: CoreDataStack = ContextManager.shared,
         keychainUtils: KeychainUtils = KeychainUtils(),
         sharedDefaults: UserPersistentRepository? = UserDefaults(suiteName: WPAppGroupName),
         localFileStore: LocalFileStore = FileManager.default) {
        self.contextManager = contextManager
        self.keychainUtils = keychainUtils
        self.sharedDefaults = sharedDefaults
        self.localFileStore = localFileStore
    }

    /// Helper method for creating an instance in Obj-C
    ///
    class func instance() -> SharedDataIssueSolver {
        return SharedDataIssueSolver()
    }

    func migrateAuthKey() {
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext),
              let username = account.username else {
            return
        }
        migrateAuthKey(for: username)
    }

    /// Resolve shared data issue by splitting the keys used to store authentication token and supporting data.
    /// To be safe, the method only "migrates" the data when the user is logged in, and there's a good chance that
    /// both apps are logged in with the same account.
    ///
    func migrateAuthKey(for username: String) {
        guard AppConfiguration.isJetpack,
              let token = try? keychainUtils.password(for: username, serviceName: WPAccountConstants.authToken.rawValue) else {
            return
        }

        // If the token has already been migrated, no need to resolve the issue again.
        // There might also be a possibility that the user logged in to JP by themselves. In which, we won't need to migrate.
        if let _ = try? keychainUtils.password(for: username, serviceName: WPAccountConstants.authToken.valueForJetpack) {
            return
        }

        // if authToken for the account username exists, move it to the authToken location for JP.
        try? keychainUtils.store(username: username,
                                 password: token,
                                 serviceName: WPAccountConstants.authToken.valueForJetpack,
                                 updateExisting: true)

        migrateExtensionsKeychainData()
    }

    func migrateExtensionsKeychainData() {
        copyTodayWidgetKeychain()
        copyShareExtensionKeychain()
        copyNotificationExtensionKeychain()
    }

    func migrateExtensionsData() {
        copyTodayWidgetDataToJetpack()
        copyShareExtensionDataToJetpack()
        copyNotificationsExtensionDataToJetpack()
    }

    /// Copies WP's Today Widget data (in Keychain and User Defaults) into JP.
    ///
    /// Both WP and JP's extensions are already reading and storing data in the same location, but in case of Today Widget,
    /// the keys used for Keychain and User Defaults are differentiated to prevent one app overwriting the other.
    ///
    /// Note: This method is not private for unit testing purposes.
    /// It requires time to properly mock the dependencies in `importData`.
    ///
    func copyTodayWidgetDataToJetpack() {
        copyTodayWidgetKeychain()
        copyTodayWidgetUserDefaults()
        copyTodayWidgetCacheFiles()
    }

    /// Copies WP's Share extension data (in Keychain and User Defaults) into JP.
    ///
    /// Note: This method is not private for unit testing purposes.
    /// It requires time to properly mock the dependencies in `importData`.
    func copyShareExtensionDataToJetpack() {
        copyShareExtensionKeychain()
        copyShareExtensionUserDefaults()
    }

    /// Copies WP's Notifications extension data (in Keychain) into JP.
    ///
    /// Note: This method is not private for unit testing purposes.
    /// It requires time to properly mock the dependencies in `importData`.
    func copyNotificationsExtensionDataToJetpack() {
        copyNotificationExtensionKeychain()
    }

    private func copySharedDefaults(_ keys: [MigratableConstant]) {
        guard let sharedDefaults else {
            return
        }

        keys.forEach { key in
            // go to the next key if there's nothing stored under the current key.
            guard let objectToMigrate = sharedDefaults.object(forKey: key.rawValue) else {
                return
            }

            sharedDefaults.set(objectToMigrate, forKey: key.valueForJetpack)
        }
    }

}

// MARK: - Helpers

fileprivate protocol MigratableConstant {
    var rawValue: String { get }
    var valueForJetpack: String { get }
}

// MARK: - Account Auth Token Helpers

private extension SharedDataIssueSolver {

    enum WPAccountConstants: String, MigratableConstant {
        case authToken = "public-api.wordpress.com"

        var valueForJetpack: String {
            switch self {
            case .authToken:
                return "jetpack.public-api.wordpress.com"
            }
        }
    }

}

// MARK: - Today Widget Helpers

private extension SharedDataIssueSolver {

    func copyTodayWidgetKeychain() {
        guard let authToken = try? keychainUtils.password(for: WPWidgetConstants.keychainTokenKey.rawValue,
                                                          serviceName: WPWidgetConstants.keychainServiceName.rawValue,
                                                          accessGroup: WPAppKeychainAccessGroup) else {
            return
        }

        try? keychainUtils.store(username: WPWidgetConstants.keychainTokenKey.valueForJetpack,
                                 password: authToken,
                                 serviceName: WPWidgetConstants.keychainServiceName.valueForJetpack,
                                 updateExisting: true)
    }

    func copyTodayWidgetUserDefaults() {
        let userDefaultKeys: [WPWidgetConstants] = [
            .userDefaultsSiteIdKey,
            .userDefaultsLoggedInKey,
            .statsUserDefaultsSiteIdKey,
            .statsUserDefaultsSiteUrlKey,
            .statsUserDefaultsSiteNameKey,
            .statsUserDefaultsSiteTimeZoneKey
        ]

        copySharedDefaults(userDefaultKeys)
    }

    func copyTodayWidgetCacheFiles() {
        let fileNames: [WPWidgetConstants] = [
            .todayFilename,
            .allTimeFilename,
            .thisWeekFilename,
            .statsTodayFilename,
            .statsThisWeekFilename,
            .statsAllTimeFilename
        ]

        fileNames.forEach { fileName in
            guard let sourceURL = localFileStore.containerURL(forAppGroup: WPAppGroupName)?.appendingPathComponent(fileName.rawValue),
                  let targetURL = localFileStore.containerURL(forAppGroup: WPAppGroupName)?.appendingPathComponent(fileName.valueForJetpack),
                  localFileStore.fileExists(at: sourceURL) else {
                return
            }

            if localFileStore.fileExists(at: targetURL) {
                try? localFileStore.removeItem(at: targetURL)
            }

            try? localFileStore.copyItem(at: sourceURL, to: targetURL)
        }
    }

    /// Keys relevant for migration, copied from WidgetConfiguration.
    ///
    enum WPWidgetConstants: String, MigratableConstant {
        // Constants for Home Widget
        case keychainTokenKey = "OAuth2Token"
        case keychainServiceName = "TodayWidget"
        case userDefaultsSiteIdKey = "WordPressHomeWidgetsSiteId"
        case userDefaultsLoggedInKey = "WordPressHomeWidgetsLoggedIn"
        case todayFilename = "HomeWidgetTodayData.plist" // HomeWidgetTodayData
        case allTimeFilename = "HomeWidgetAllTimeData.plist" // HomeWidgetAllTimeData
        case thisWeekFilename = "HomeWidgetThisWeekData.plist" // HomeWidgetThisWeekData

        // Constants for Stats Widget
        case statsUserDefaultsSiteIdKey = "WordPressTodayWidgetSiteId"
        case statsUserDefaultsSiteNameKey = "WordPressTodayWidgetSiteName"
        case statsUserDefaultsSiteUrlKey = "WordPressTodayWidgetSiteUrl"
        case statsUserDefaultsSiteTimeZoneKey = "WordPressTodayWidgetTimeZone"
        case statsTodayFilename = "TodayData.plist" // TodayWidgetStats
        case statsThisWeekFilename = "ThisWeekData.plist" // ThisWeekWidgetStats
        case statsAllTimeFilename = "AllTimeData.plist" // AllTimeWidgetStats

        var valueForJetpack: String {
            switch self {
            case .keychainTokenKey:
                return "OAuth2Token"
            case .keychainServiceName:
                return "JetpackTodayWidget"
            case .userDefaultsSiteIdKey:
                return "JetpackHomeWidgetsSiteId"
            case .userDefaultsLoggedInKey:
                return "JetpackHomeWidgetsLoggedIn"
            case .todayFilename:
                return "JetpackHomeWidgetTodayData.plist"
            case .allTimeFilename:
                return "JetpackHomeWidgetAllTimeData.plist"
            case .thisWeekFilename:
                return "JetpackHomeWidgetThisWeekData.plist"
            case .statsUserDefaultsSiteIdKey:
                return "JetpackTodayWidgetSiteId"
            case .statsUserDefaultsSiteNameKey:
                return "JetpackTodayWidgetSiteName"
            case .statsUserDefaultsSiteUrlKey:
                return "JetpackTodayWidgetSiteUrl"
            case .statsUserDefaultsSiteTimeZoneKey:
                return "JetpackTodayWidgetTimeZone"
            case .statsTodayFilename:
                return "JetpackTodayData.plist"
            case .statsThisWeekFilename:
                return "JetpackThisWeekData.plist"
            case .statsAllTimeFilename:
                return "JetpackAllTimeData.plist"
            }
        }
    }
}

// MARK: - Share Extension Helpers

private extension SharedDataIssueSolver {

    func copyShareExtensionKeychain() {
        guard let authToken = try? keychainUtils.password(for: WPShareExtensionConstants.keychainTokenKey.rawValue,
                                                          serviceName: WPShareExtensionConstants.keychainServiceName.rawValue,
                                                          accessGroup: WPAppKeychainAccessGroup) else {
            return
        }

        try? keychainUtils.store(username: WPShareExtensionConstants.keychainTokenKey.valueForJetpack,
                                 password: authToken,
                                 serviceName: WPShareExtensionConstants.keychainServiceName.valueForJetpack,
                                 updateExisting: true)
    }

    func copyShareExtensionUserDefaults() {
        let userDefaultKeys: [WPShareExtensionConstants] = [
            .userDefaultsPrimarySiteName,
            .userDefaultsPrimarySiteID,
            .userDefaultsLastUsedSiteName,
            .userDefaultsLastUsedSiteID,
            .maximumMediaDimensionKey,
            .recentSitesKey
        ]

        copySharedDefaults(userDefaultKeys)
    }

    /// Keys relevant for migration, copied from ExtensionConfiguration.
    ///
    enum WPShareExtensionConstants: String, MigratableConstant {

        case keychainUsernameKey = "Username"
        case keychainTokenKey = "OAuth2Token"
        case keychainServiceName = "ShareExtension"
        case userDefaultsPrimarySiteName = "WPShareUserDefaultsPrimarySiteName"
        case userDefaultsPrimarySiteID = "WPShareUserDefaultsPrimarySiteID"
        case userDefaultsLastUsedSiteName = "WPShareUserDefaultsLastUsedSiteName"
        case userDefaultsLastUsedSiteID = "WPShareUserDefaultsLastUsedSiteID"
        case maximumMediaDimensionKey = "WPShareExtensionMaximumMediaDimensionKey"
        case recentSitesKey = "WPShareExtensionRecentSitesKey"

        var valueForJetpack: String {
            switch self {
            case .keychainUsernameKey:
                return "JPUsername"
            case .keychainTokenKey:
                return "JPOAuth2Token"
            case .keychainServiceName:
                return "JPShareExtension"
            case .userDefaultsPrimarySiteName:
                return "JPShareUserDefaultsPrimarySiteName"
            case .userDefaultsPrimarySiteID:
                return "JPShareUserDefaultsPrimarySiteID"
            case .userDefaultsLastUsedSiteName:
                return "JPShareUserDefaultsLastUsedSiteName"
            case .userDefaultsLastUsedSiteID:
                return "JPShareUserDefaultsLastUsedSiteID"
            case .maximumMediaDimensionKey:
                return "JPShareExtensionMaximumMediaDimensionKey"
            case .recentSitesKey:
                return "JPShareExtensionRecentSitesKey"
            }
        }
    }
}

// MARK: - Notifications Extension Helpers

private extension SharedDataIssueSolver {

    func copyNotificationExtensionKeychain() {
        guard let authToken = try? keychainUtils.password(for: WPNotificationsExtensionConstants.keychainTokenKey.rawValue,
                                                          serviceName: WPNotificationsExtensionConstants.keychainServiceName.rawValue,
                                                          accessGroup: WPAppKeychainAccessGroup) else {
            return
        }

        try? keychainUtils.store(username: WPNotificationsExtensionConstants.keychainTokenKey.valueForJetpack,
                                 password: authToken,
                                 serviceName: WPNotificationsExtensionConstants.keychainServiceName.valueForJetpack,
                                 updateExisting: true)
    }

    /// Keys relevant for migration, copied from ExtensionConfiguration.
    ///
    enum WPNotificationsExtensionConstants: String {

        case keychainServiceName = "NotificationServiceExtension"
        case keychainTokenKey = "OAuth2Token"
        case keychainUsernameKey = "Username"
        case keychainUserIDKey = "UserID"

        var valueForJetpack: String {
            switch self {
            case .keychainServiceName:
                return "JPNotificationServiceExtension"
            case .keychainTokenKey:
                return "JPOAuth2Token"
            case .keychainUsernameKey:
                return "JPUsername"
            case .keychainUserIDKey:
                return "JPUserID"
            }
        }
    }
}
