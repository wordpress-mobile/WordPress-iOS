import Foundation

struct AppUpdateType {
    let appStoreInfo: AppStoreLookupResponse.AppStoreInfo
    let isRequired: Bool
}

final class AppUpdateCoordinator {
    private let currentVersion: String?
    private let currentOsVersion: String
    private let service: AppStoreSearchProtocol
    private let presenter: AppUpdatePresenterProtocol
    private let remoteConfigStore: RemoteConfigStore
    private let store: UserPersistentRepository
    private let isJetpack: Bool
    private let isLoggedIn: Bool
    private let isInAppUpdatesEnabled: Bool
    private let delayInDays: Int

    init(
        currentVersion: String?,
        currentOsVersion: String = UIDevice.current.systemVersion,
        service: AppStoreSearchProtocol = AppStoreSearchService(),
        presenter: AppUpdatePresenterProtocol = AppUpdatePresenter(),
        remoteConfigStore: RemoteConfigStore = RemoteConfigStore(),
        store: UserPersistentRepository = UserDefaults.standard,
        isJetpack: Bool = AppConfiguration.isJetpack,
        isLoggedIn: Bool = AccountHelper.isLoggedIn,
        isInAppUpdatesEnabled: Bool = RemoteFeatureFlag.inAppUpdates.enabled(),
        delayInDays: Int = 7
    ) {
        self.currentVersion = currentVersion
        self.currentOsVersion = currentOsVersion
        self.service = service
        self.presenter = presenter
        self.remoteConfigStore = remoteConfigStore
        self.store = store
        self.isJetpack = isJetpack
        self.isLoggedIn = isLoggedIn
        self.isInAppUpdatesEnabled = isInAppUpdatesEnabled
        self.delayInDays = delayInDays
    }

    @MainActor
    func checkForAppUpdates() async {
        guard isInAppUpdatesEnabled else {
            return
        }
        guard isLoggedIn else {
            return
        }
        guard let updateType = await appUpdateType else {
            return
        }

        let appStoreInfo = updateType.appStoreInfo
        if updateType.isRequired {
            presenter.showBlockingUpdate(using: appStoreInfo)
        } else {
            presenter.showNotice(using: appStoreInfo)
            lastSeenFlexibleUpdateDate = Date.now
        }
    }

    private var appUpdateType: AppUpdateType? {
        get async {
            guard let currentVersion, shouldFetchAppStoreInfo else {
                return nil
            }
            guard let appStoreInfo = await fetchAppStoreInfo() else {
                return nil
            }
            guard !currentOsVersion.isLower(than: appStoreInfo.minimumOsVersion) else {
                // Can't update if the device OS version is lower than the minimum OS version
                return nil
            }
            guard appStoreInfo.currentVersionHasBeenReleased(for: delayInDays) else {
                return nil
            }
            if let blockingVersion, currentVersion.isLower(than: blockingVersion), blockingVersion.isLowerThanOrEqual(to: appStoreInfo.version) {
                return AppUpdateType(appStoreInfo: appStoreInfo, isRequired: true)
            }
            if currentVersion.isLower(than: appStoreInfo.version), shouldShowFlexibleUpdate {
                return AppUpdateType(appStoreInfo: appStoreInfo, isRequired: false)
            }
            return nil
        }
    }

    private var blockingVersion: String? {
        let parameter: RemoteConfigParameter = isJetpack
            ? .jetpackInAppUpdateBlockingVersion
            : .wordPressInAppUpdateBlockingVersion
        return parameter.value(using: remoteConfigStore)
    }

    private func fetchAppStoreInfo() async -> AppStoreLookupResponse.AppStoreInfo? {
        do {
            let response = try await service.lookup()
            lastFetchedAppStoreInfoDate = Date.now
            return response.results.first { $0.trackId == Int(service.appID) }
        } catch {
            DDLogError("Error fetching app store info: \(error)")
            return nil
        }
    }
}

// MARK: - Store

extension AppUpdateCoordinator {
    private var lastFetchedAppStoreInfoDate: Date? {
        get {
            store.object(forKey: Constants.lastFetchedAppStoreInfoDateKey) as? Date
        }
        set {
            store.set(newValue, forKey: Constants.lastFetchedAppStoreInfoDateKey)
        }
    }

    private var shouldFetchAppStoreInfo: Bool {
        guard let lastFetchedAppStoreInfoDate else {
            return true
        }
        guard let daysElapsed = Calendar.current.dateComponents([.day], from: lastFetchedAppStoreInfoDate, to: Date.now).day else {
            return false
        }
        return daysElapsed > Constants.lastFetchedAppStoreInfoThresholdInDays
    }

    private var flexibleIntervalInDays: Int? {
        RemoteConfigParameter.inAppUpdateFlexibleIntervalInDays.value(using: remoteConfigStore)
    }

    private var lastSeenFlexibleUpdateDate: Date? {
        get {
            store.object(forKey: Constants.lastSeenFlexibleUpdateDateKey) as? Date
        }
        set {
            store.set(newValue, forKey: Constants.lastSeenFlexibleUpdateDateKey)
        }
    }

    private var shouldShowFlexibleUpdate: Bool {
        guard let flexibleIntervalInDays else {
            wpAssertionFailure("Remote config value missing or invalid")
            return false
        }
        guard let lastSeenFlexibleUpdateDate else {
            return true
        }
        guard let daysElapsed = Calendar.current.dateComponents([.day], from: lastSeenFlexibleUpdateDate, to: Date.now).day else {
            return false
        }
        return daysElapsed > flexibleIntervalInDays
    }
}

private enum Constants {
    static let lastSeenFlexibleUpdateDateKey = "last-seen-flexible-update-date-key"
    static let lastFetchedAppStoreInfoDateKey = "last-fetched-app-store-info-date-key"
    static let lastFetchedAppStoreInfoThresholdInDays = 1
}

private extension String {
    func isLower(than anotherVersionString: String) -> Bool {
        self.compare(anotherVersionString, options: .numeric) == .orderedAscending
    }

    func isLowerThanOrEqual(to anotherVersionString: String) -> Bool {
        [ComparisonResult.orderedSame, .orderedAscending].contains(self.compare(anotherVersionString, options: .numeric))
    }
}
