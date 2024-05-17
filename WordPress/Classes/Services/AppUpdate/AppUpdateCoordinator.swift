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
    private let isJetpack: Bool
    private let isLoggedIn: Bool
    private let isInAppUpdatesEnabled: Bool

    init(
        currentVersion: String?,
        currentOsVersion: String = UIDevice.current.systemVersion,
        service: AppStoreSearchProtocol = AppStoreSearchService(),
        presenter: AppUpdatePresenterProtocol = AppUpdatePresenter(),
        remoteConfigStore: RemoteConfigStore = RemoteConfigStore(),
        isJetpack: Bool = AppConfiguration.isJetpack,
        isLoggedIn: Bool = AccountHelper.isLoggedIn,
        isInAppUpdatesEnabled: Bool = RemoteFeatureFlag.inAppUpdates.enabled()
    ) {
        self.currentVersion = currentVersion
        self.currentOsVersion = currentOsVersion
        self.service = service
        self.presenter = presenter
        self.remoteConfigStore = remoteConfigStore
        self.isJetpack = isJetpack
        self.isLoggedIn = isLoggedIn
        self.isInAppUpdatesEnabled = isInAppUpdatesEnabled
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

        if updateType.isRequired {
            presenter.showBlockingUpdate(using: updateType.appStoreInfo)
        } else {
            presenter.showNotice(using: updateType.appStoreInfo)
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
            if let blockingVersion, currentVersion.isLower(than: blockingVersion), blockingVersion.isLowerThanOrEqual(to: appStoreInfo.version) {
                return AppUpdateType(appStoreInfo: appStoreInfo, isRequired: true)
            }
            if currentVersion.isLower(than: appStoreInfo.version) {
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

private extension String {
    func isLower(than anotherVersionString: String) -> Bool {
        self.compare(anotherVersionString, options: .numeric) == .orderedAscending
    }

    func isLowerThanOrEqual(to anotherVersionString: String) -> Bool {
        [ComparisonResult.orderedSame, .orderedAscending].contains(self.compare(anotherVersionString, options: .numeric))
    }
}
