import Foundation
import WordPressFlux

protocol InAppUpdatePresenterProtocol {
    func showNotice()
    func showBlockingUpdate(using appStoreInfo: AppStoreInfo)
    func openAppStore()
}

final class InAppUpdatePresenter: InAppUpdatePresenterProtocol {
    func showNotice() {
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

    func showBlockingUpdate(using appStoreInfo: AppStoreInfo) {
        guard let window = UIApplication.sharedIfAvailable()?.mainWindow,
              let topViewController = window.topmostPresentedViewController,
              !((topViewController as? UINavigationController)?.viewControllers.first is BlockingUpdateViewController) else {
            wpAssertionFailure("Failed to show blocking update view")
            return
        }
        let viewModel = AppStoreInfoViewModel(appStoreInfo) { [weak self] in
            self?.openAppStore()
        }
        let controller = BlockingUpdateViewController(viewModel: viewModel)
        let navigation = UINavigationController(rootViewController: controller)
        topViewController.present(navigation, animated: true)
    }

    func openAppStore() {
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
