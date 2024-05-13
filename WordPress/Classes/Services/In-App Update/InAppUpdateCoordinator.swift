import Foundation
import WordPressFlux

enum InAppUpdateType {
    case flexible
    case blocking(AppStoreInfo)
}

final class InAppUpdateCoordinator {

    private let service: AppStoreSearchService
    private let remoteConfigStore: RemoteConfigStore

    init(
        service: AppStoreSearchService = AppStoreSearchService(),
        remoteConfigStore: RemoteConfigStore = RemoteConfigStore()
    ) {
        self.service = service
        self.remoteConfigStore = remoteConfigStore
    }

    @MainActor
    func showUpdateIfNeeded() {
        Task {
            guard let updateType = await inAppUpdateType else {
                return
            }

            switch updateType {
            case .flexible:
                showNotice()
            case .blocking(let appStoreInfo):
                showBlockingUpdate(using: appStoreInfo)
            }
        }
    }

    private var inAppUpdateType: InAppUpdateType? {
        get async {
            guard let versionNumber else {
                return nil
            }

            if let appStoreInfo = await fetchAppStoreInfo() {
                if let blockingVersionNumber, versionNumber < blockingVersionNumber {
                    return .blocking(appStoreInfo)
                }
                if let appStoreVersionNumber = Double(appStoreInfo.version), versionNumber < appStoreVersionNumber {
                    return .flexible
                }
            }

            return nil
        }
    }

    private var versionNumber: Double? {
        guard
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let versionNumber = Double(version)
        else {
            DDLogError("No CFBundleShortVersionString found in Info.plist")
            return nil
        }
        return versionNumber
    }

    private var blockingVersionNumber: Double? {
        let parameter: RemoteConfigParameter = AppConfiguration.isJetpack
            ? .jetpackInAppUpdateBlockingVersion
            : .wordPressInAppUpdateBlockingVersion
        return parameter.value(using: remoteConfigStore)
    }

    private func fetchAppStoreInfo() async -> AppStoreInfo? {
        do {
            let response = try await service.lookup(appID: AppConstants.itunesAppID)
            return response.results.first { $0.trackId == Int(AppConstants.itunesAppID) }
        } catch {
            DDLogError("Error fetching app store info: \(error)")
            return nil
        }
    }

    private func showNotice() {
        let notice = Notice(
            title: Strings.Notice.title,
            message: Strings.Notice.message,
            feedbackType: .warning,
            style: InAppUpdateNoticeStyle(),
            actionTitle: Strings.Notice.update
        ) { [weak self] _ in
            self?.openAppStore()
        }
        ActionDispatcher.dispatch(NoticeAction.post(notice))
        // Todo: if the notice is dismissed, show notice again after a defined interval
    }

    private func showBlockingUpdate(using appStoreInfo: AppStoreInfo) {
        guard let window = UIApplication.sharedIfAvailable()?.mainWindow,
              let topViewController = window.topmostPresentedViewController,
              !((topViewController as? UINavigationController)?.viewControllers.first is BlockingUpdateViewController) else {
            wpAssertionFailure("Failed to show blocking update view")
            return
        }
        let viewModel = BlockingUpdateViewModel(appStoreInfo: appStoreInfo) { [weak self] in
            self?.openAppStore()
        }
        let controller = BlockingUpdateViewController(viewModel: viewModel)
        let navigation = UINavigationController(rootViewController: controller)
        topViewController.present(navigation, animated: true)
    }

    private func openAppStore() {
        // Todo
    }
}

private enum Strings {
    enum Notice {
        static let title = NSLocalizedString("inAppUpdate.notice.title", value: "App Update Available", comment: "Title for notice displayed when there's a newer version of the app available")
        static let message = NSLocalizedString("inAppUpdate.notice.message", value: "To use this app, download the latest version.", comment: "Message for notice displayed when there's a newer version of the app available")
        static let update = NSLocalizedString("inAppUpdate.notice.update", value: "Update", comment: "Button title for notice displayed when there's a newer version of the app available")
    }
}
