final class DataMigrator {

    private let coreDataStack: CoreDataStack
    private let backupLocation: URL?
    private let keychainUtils: KeychainUtils
    private let localDefaults: UserDefaults
    private let sharedDefaults: UserDefaults?
    private let localFileStore: LocalFileStore

    init(coreDataStack: CoreDataStack = ContextManager.sharedInstance(),
         backupLocation: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.wordpress")?.appendingPathComponent("WordPress.sqlite"),
         keychainUtils: KeychainUtils = KeychainUtils(),
         localDefaults: UserDefaults = UserDefaults.standard,
         sharedDefaults: UserDefaults? = UserDefaults(suiteName: WPAppGroupName),
         localFileStore: LocalFileStore = FileManager.default) {
        self.coreDataStack = coreDataStack
        self.backupLocation = backupLocation
        self.keychainUtils = keychainUtils
        self.localDefaults = localDefaults
        self.sharedDefaults = sharedDefaults
        self.localFileStore = localFileStore
    }

    enum DataMigratorError: Error {
        case localDraftsNotSynced
        case databaseCopyError
        case keychainError
        case sharedUserDefaultsNil
    }

    func exportData(completion: ((Result<Void, DataMigratorError>) -> Void)? = nil) {
        guard isLocalDraftsSynced() else {
            completion?(.failure(.localDraftsNotSynced))
            return
        }
        guard let backupLocation, copyDatabase(to: backupLocation) else {
            completion?(.failure(.databaseCopyError))
            return
        }
        guard copyUserDefaults(from: localDefaults, to: sharedDefaults) else {
            completion?(.failure(.sharedUserDefaultsNil))
            return
        }
        BloggingRemindersScheduler.handleRemindersMigration()
        completion?(.success(()))
    }

    func importData(completion: ((Result<Void, DataMigratorError>) -> Void)? = nil) {
        guard let backupLocation, restoreDatabase(from: backupLocation) else {
            completion?(.failure(.databaseCopyError))
            return
        }
        guard copyUserDefaults(from: sharedDefaults, to: localDefaults) else {
            completion?(.failure(.sharedUserDefaultsNil))
            return
        }

        copyTodayWidgetDataToJetpack()
        copyShareExtensionDataToJetpack()
        BloggingRemindersScheduler.handleRemindersMigration()
        completion?(.success(()))
    }

    /// Copies WP's Today Widget data (in Keychain and User Defaults) into JP.
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
    func copyShareExtensionDataToJetpack() {
        copyShareExtensionKeychain()
        copyShareExtensionUserDefaults()
    }
}

// MARK: - Private Functions

private extension DataMigrator {

    func isLocalDraftsSynced() -> Bool {
        let fetchRequest = NSFetchRequest<Post>(entityName: String(describing: Post.self))
        fetchRequest.predicate = NSPredicate(format: "status = %@ && (remoteStatusNumber = %@ || remoteStatusNumber = %@ || remoteStatusNumber = %@ || remoteStatusNumber = %@)",
                                             BasePost.Status.draft.rawValue,
                                             NSNumber(value: AbstractPostRemoteStatus.pushing.rawValue),
                                             NSNumber(value: AbstractPostRemoteStatus.failed.rawValue),
                                             NSNumber(value: AbstractPostRemoteStatus.local.rawValue),
                                             NSNumber(value: AbstractPostRemoteStatus.pushingMedia.rawValue))
        guard let count = try? coreDataStack.mainContext.count(for: fetchRequest) else {
            return false
        }

        return count == 0
    }

    func copyDatabase(to destination: URL) -> Bool {
        do {
            try coreDataStack.createStoreCopy(to: destination)
        } catch {
            DDLogError("Error copying database: \(error)")
            return false
        }
        return true
    }

    func restoreDatabase(from source: URL) -> Bool {
        do {
            try coreDataStack.restoreStoreCopy(from: source)
        } catch {
            DDLogError("Error restoring database: \(error)")
            return false
        }
        return true
    }

    func copyKeychain(from sourceAccessGroup: String?, to destinationAccessGroup: String?) -> Bool {
        do {
            try keychainUtils.copyKeychain(from: sourceAccessGroup, to: destinationAccessGroup)
        } catch {
            DDLogError("Error copying keychain: \(error)")
            return false
        }

        return true
    }

    func copyUserDefaults(from source: UserDefaults?, to destination: UserDefaults?) -> Bool {
        guard let source, let destination else {
            return false
        }
        let data = source.dictionaryRepresentation()
        for (key, value) in data {
            destination.set(value, forKey: key)
        }

        return true
    }
}

// MARK: - Today Widget Helpers

private extension DataMigrator {

    func copyTodayWidgetKeychain() {
        guard let authToken = try? keychainUtils.password(for: WPWidgetConstants.keychainTokenKey.rawValue,
                                                          serviceName: WPWidgetConstants.keychainServiceName.rawValue,
                                                          accessGroup: WPAppKeychainAccessGroup) else {
            return
        }

        try? keychainUtils.store(username: WPWidgetConstants.keychainTokenKey.valueForJetpack(),
                                 password: authToken,
                                 serviceName: WPWidgetConstants.keychainServiceName.valueForJetpack(),
                                 updateExisting: true)
    }

    func copyTodayWidgetUserDefaults() {
        guard let sharedDefaults else {
            return
        }

        let userDefaultKeys: [WPWidgetConstants] = [
            .userDefaultsSiteIdKey,
            .userDefaultsLoggedInKey,
            .statsUserDefaultsSiteIdKey,
            .statsUserDefaultsSiteUrlKey,
            .statsUserDefaultsSiteNameKey,
            .statsUserDefaultsSiteTimeZoneKey
        ]

        userDefaultKeys.forEach { key in
            // go to the next key if there's nothing stored under the current key.
            guard let objectToMigrate = sharedDefaults.object(forKey: key.rawValue) else {
                return
            }

            sharedDefaults.set(objectToMigrate, forKey: key.valueForJetpack())
        }
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
                  let targetURL = localFileStore.containerURL(forAppGroup: WPAppGroupName)?.appendingPathComponent(fileName.valueForJetpack()),
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
    enum WPWidgetConstants: String {
        // Constants for Home Widget
        case keychainTokenKey = "OAuth2Token"
        case keychainServiceName = "TodayWidget"
        case userDefaultsSiteIdKey = "WordPressHomeWidgetsSiteId"
        case userDefaultsLoggedInKey = "WordPressHomeWidgetsLoggedIn"
        case todayFilename = "HomeWidgetTodayData.plist"
        case allTimeFilename = "HomeWidgetAllTimeData.plist"
        case thisWeekFilename = "HomeWidgetThisWeekData.plist" // HomeWidgetAllTimeData

        // Constants for Stats Widget
        case statsUserDefaultsSiteIdKey = "WordPressTodayWidgetSiteId"
        case statsUserDefaultsSiteNameKey = "WordPressTodayWidgetSiteName"
        case statsUserDefaultsSiteUrlKey = "WordPressTodayWidgetSiteUrl"
        case statsUserDefaultsSiteTimeZoneKey = "WordPressTodayWidgetTimeZone"
        case statsTodayFilename = "TodayData.plist" // TodayWidgetStats
        case statsThisWeekFilename = "ThisWeekData.plist" // ThisWeekWidgetStats
        case statsAllTimeFilename = "AllTimeData.plist" // AllTimeWidgetStats

        func valueForJetpack() -> String {
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

// MARK: - App Extensions Helpers

private extension DataMigrator {

    func copyShareExtensionKeychain() {
        guard let authToken = try? keychainUtils.password(for: WPShareExtensionConstants.keychainTokenKey.rawValue,
                                                          serviceName: WPShareExtensionConstants.keychainServiceName.rawValue,
                                                          accessGroup: WPAppKeychainAccessGroup) else {
            return
        }

        try? keychainUtils.store(username: WPShareExtensionConstants.keychainTokenKey.valueForJetpack(),
                                 password: authToken,
                                 serviceName: WPShareExtensionConstants.keychainServiceName.valueForJetpack(),
                                 updateExisting: true)
    }

    func copyShareExtensionUserDefaults() {
        guard let sharedDefaults else {
            return
        }

        let userDefaultKeys: [WPShareExtensionConstants] = [
            .userDefaultsPrimarySiteName,
            .userDefaultsPrimarySiteID,
            .userDefaultsLastUsedSiteName,
            .userDefaultsLastUsedSiteID,
            .maximumMediaDimensionKey,
            .recentSitesKey
        ]

        userDefaultKeys.forEach { key in
            // go to the next key if there's nothing stored under the current key.
            guard let objectToMigrate = sharedDefaults.object(forKey: key.rawValue) else {
                return
            }

            sharedDefaults.set(objectToMigrate, forKey: key.valueForJetpack())
        }
    }

    /// Keys relevant for migration, copied from ExtensionConfiguration.
    ///
    enum WPShareExtensionConstants: String {

        // Constants for share extension
        case keychainUsernameKey = "Username"
        case keychainTokenKey = "OAuth2Token"
        case keychainServiceName = "ShareExtension"
        case userDefaultsPrimarySiteName = "WPShareUserDefaultsPrimarySiteName"
        case userDefaultsPrimarySiteID = "WPShareUserDefaultsPrimarySiteID"
        case userDefaultsLastUsedSiteName = "WPShareUserDefaultsLastUsedSiteName"
        case userDefaultsLastUsedSiteID = "WPShareUserDefaultsLastUsedSiteID"
        case maximumMediaDimensionKey = "WPShareExtensionMaximumMediaDimensionKey"
        case recentSitesKey = "WPShareExtensionRecentSitesKey"

        func valueForJetpack() -> String {
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
