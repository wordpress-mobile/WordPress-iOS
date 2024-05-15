import Foundation

enum AppUpdateType {
    case flexible(AppStoreInfo)
    case blocking(AppStoreInfo)
}

final class AppUpdateCoordinator {

    private let currentVersion: String?
    private let currentOsVersion: String
    private let service: AppStoreSearchProtocol
    private let presenter: AppUpdatePresenterProtocol
    private let remoteConfigStore: RemoteConfigStore
    private let isJetpack: Bool
    private let isLoggedIn: Bool

    init(
        currentVersion: String?,
        currentOsVersion: String = UIDevice.current.systemVersion,
        service: AppStoreSearchProtocol = AppStoreSearchService(),
        presenter: AppUpdatePresenterProtocol = AppUpdatePresenter(),
        remoteConfigStore: RemoteConfigStore = RemoteConfigStore(),
        isJetpack: Bool = AppConfiguration.isJetpack,
        isLoggedIn: Bool = AccountHelper.isLoggedIn
    ) {
        self.currentVersion = currentVersion
        self.currentOsVersion = currentOsVersion
        self.service = service
        self.presenter = presenter
        self.remoteConfigStore = remoteConfigStore
        self.isJetpack = isJetpack
        self.isLoggedIn = isLoggedIn
    }

    @MainActor
    func checkForAppUpdates() async {
        guard isLoggedIn else {
            return
        }

        guard let updateType = await inAppUpdateType else {
            return
        }

        switch updateType {
        case .flexible(let appStoreInfo):
            presenter.showNotice(using: appStoreInfo)
        case .blocking(let appStoreInfo):
            presenter.showBlockingUpdate(using: appStoreInfo)
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
                return .blocking(appStoreInfo)
            }
            if currentVersion.isLower(than: appStoreInfo.version) {
                return .flexible(appStoreInfo)
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

    private func fetchAppStoreInfo() async -> AppStoreInfo? {
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
