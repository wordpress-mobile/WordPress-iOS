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
        guard let updateType = await inAppUpdateType else {
            return
        }

        let appStoreInfo = updateType.appStoreInfo
        if updateType.isRequired {
            presenter.showBlockingUpdate(using: appStoreInfo)
        } else {
            presenter.showNotice(using: appStoreInfo)
            setLastSeenFlexibleUpdateDate(Date.now, for: appStoreInfo.version)
        }
    }

    private var inAppUpdateType: AppUpdateType? {
        get async {
            guard let currentVersion else {
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
            if currentVersion.isLower(than: appStoreInfo.version), shouldShowFlexibleUpdate(for: appStoreInfo.version) {
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
            return response.results.first { $0.trackId == Int(service.appID) }
        } catch {
            DDLogError("Error fetching app store info: \(error)")
            return nil
        }
    }
}

// MARK: - Flexible Interval

extension AppUpdateCoordinator {
    private var flexibleIntervalInDays: Int? {
        RemoteConfigParameter.inAppUpdateFlexibleIntervalInDays.value(using: remoteConfigStore)
    }

    private func lastSeenFlexibleUpdateKey(for version: String) -> String {
        return "\(version)-\(Constants.lastSeenFlexibleUpdateDateKey)"
    }

    private func getLastSeenFlexibleUpdateDate(for version: String) -> Date? {
        store.object(forKey: lastSeenFlexibleUpdateKey(for: version)) as? Date
    }

    private func setLastSeenFlexibleUpdateDate(_ date: Date, for version: String) {
        store.set(date, forKey: lastSeenFlexibleUpdateKey(for: version))
    }

    private func shouldShowFlexibleUpdate(for version: String) -> Bool {
        guard let flexibleIntervalInDays else {
            return false
        }
        guard let lastSeenFlexibleUpdateDate = getLastSeenFlexibleUpdateDate(for: version) else {
            return true
        }
        let secondsInDay: TimeInterval = 86_400
        let secondsSinceLastSeen = -lastSeenFlexibleUpdateDate.timeIntervalSinceNow
        return secondsSinceLastSeen > Double(flexibleIntervalInDays) * secondsInDay
    }
}

private enum Constants {
    static let lastSeenFlexibleUpdateDateKey = "last-seen-flexible-update-date-key"
}

private extension String {
    func isLower(than anotherVersionString: String) -> Bool {
        self.compare(anotherVersionString, options: .numeric) == .orderedAscending
    }

    func isLowerThanOrEqual(to anotherVersionString: String) -> Bool {
        [ComparisonResult.orderedSame, .orderedAscending].contains(self.compare(anotherVersionString, options: .numeric))
    }
}
