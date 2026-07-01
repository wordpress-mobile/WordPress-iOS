import WordPressShared
import BuildSettingsKit

public final class SharedDataIssueSolver {

    private let contextManager: CoreDataStack
    private let appKeychain: KeychainAccessible
    private let sharedKeychain: KeychainAccessible?
    private let sharedDefaults: UserPersistentRepository?
    private let localFileStore: LocalFileStore
    private let appGroupName: String

    public init(
        contextManager: CoreDataStack = ContextManager.shared,
        appKeychain: KeychainAccessible = AppKeychain(),
        sharedKeychain: KeychainAccessible? = SharedKeychain(),
        sharedDefaults: UserPersistentRepository? = UserDefaults(suiteName: BuildSettings.current.appGroupName),
        localFileStore: LocalFileStore = FileManager.default,
        appGroupName: String = BuildSettings.current.appGroupName
    ) {
        self.contextManager = contextManager
        self.appKeychain = appKeychain
        self.sharedKeychain = sharedKeychain
        self.sharedDefaults = sharedDefaults
        self.localFileStore = localFileStore
        self.appGroupName = appGroupName
    }

    public func migrateAuthKey() {
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext) else {
            return
        }
        migrateAuthKey(for: account.username)
    }

    /// Resolve shared data issue by splitting the keys used to store authentication token and supporting data.
    /// To be safe, the method only "migrates" the data when the user is logged in, and there's a good chance that
    /// both apps are logged in with the same account.
    ///
    public func migrateAuthKey(for username: String) {
        // Explicitly the shared group: this is the one deliberate cross-app
        // keychain read in the codebase. The WordPress app publishes the
        // token there at export time (and pre-change versions wrote it
        // there by default).
        guard BuildSettings.current.brand == .jetpack,
            let sharedKeychain,
            let token = try? sharedKeychain.getPassword(
                for: username,
                serviceName: AuthTokenServiceNames.wordPress
            )
        else {
            return
        }

        // If the token has already been migrated, no need to resolve the issue again.
        // There might also be a possibility that the user logged in to JP by themselves. In which, we won't need to migrate.
        if let _ = try? appKeychain.getPassword(
            for: username,
            serviceName: AuthTokenServiceNames.jetpack
        ) {
            return
        }

        // if authToken for the account username exists, move it to the authToken location for JP.
        try? appKeychain.setPassword(
            for: username,
            to: token,
            serviceName: AuthTokenServiceNames.jetpack
        )
    }

    public func migrateExtensionsData() {
        copyTodayWidgetDataToJetpack()
        copyShareExtensionDataToJetpack()
    }

    /// Copies WP's Today Widget data (in User Defaults and local files) into JP.
    /// Note: This method is not private for unit testing purposes.
    /// It requires time to properly mock the dependencies in `importData`.
    ///
    func copyTodayWidgetDataToJetpack() {
        copyTodayWidgetUserDefaults()
        copyTodayWidgetCacheFiles()
    }

    /// Copies WP's Share extension data (in User Defaults) into JP.
    ///
    /// Note: This method is not private for unit testing purposes.
    /// It requires time to properly mock the dependencies in `importData`.
    func copyShareExtensionDataToJetpack() {
        copyShareExtensionUserDefaults()
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

// MARK: - Today Widget Helpers

private extension SharedDataIssueSolver {

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
            guard
                let sourceURL = localFileStore.containerURL(forAppGroup: appGroupName)?
                    .appendingPathComponent(fileName.rawValue),
                let targetURL = localFileStore.containerURL(forAppGroup: appGroupName)?
                    .appendingPathComponent(fileName.valueForJetpack),
                localFileStore.fileExists(at: sourceURL)
            else {
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

        case userDefaultsPrimarySiteName = "WPShareUserDefaultsPrimarySiteName"
        case userDefaultsPrimarySiteID = "WPShareUserDefaultsPrimarySiteID"
        case userDefaultsLastUsedSiteName = "WPShareUserDefaultsLastUsedSiteName"
        case userDefaultsLastUsedSiteID = "WPShareUserDefaultsLastUsedSiteID"
        case maximumMediaDimensionKey = "WPShareExtensionMaximumMediaDimensionKey"
        case recentSitesKey = "WPShareExtensionRecentSitesKey"

        var valueForJetpack: String {
            switch self {
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
