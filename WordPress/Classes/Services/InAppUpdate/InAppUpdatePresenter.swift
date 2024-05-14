import Foundation
import WordPressFlux

protocol InAppUpdatePresenterProtocol {
    func showNotice(using appStoreInfo: AppStoreInfo)
    func showBlockingUpdate(using appStoreInfo: AppStoreInfo)
    func openAppStore()
}

final class InAppUpdatePresenter: InAppUpdatePresenterProtocol {
    func showNotice(using appStoreInfo: AppStoreInfo) {
        let viewModel = AppStoreInfoViewModel(appStoreInfo) {
            self.openAppStore()
        }
        let notice = Notice(
            title: viewModel.title,
            message: viewModel.message,
            feedbackType: .warning,
            style: InAppUpdateNoticeStyle(),
            actionTitle: viewModel.updateButtonTitle,
            cancelTitle: viewModel.cancelButtonTitle
        ) { onAccepted in
            if onAccepted {
                viewModel.onUpdateTapped()
            }
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
        let viewModel = AppStoreInfoViewModel(appStoreInfo) {
            self.openAppStore()
        }
        let controller = BlockingUpdateViewController(viewModel: viewModel)
        let navigation = UINavigationController(rootViewController: controller)
        topViewController.present(navigation, animated: true)
    }

    func openAppStore() {
        // TODO
    }
}
