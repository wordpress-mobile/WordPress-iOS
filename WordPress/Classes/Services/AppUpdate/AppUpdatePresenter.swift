import Foundation
import WordPressFlux
import WordPressShared

protocol AppUpdatePresenterProtocol {
    func showNotice(using appStoreInfo: AppStoreLookupResponse.AppStoreInfo)
    func showBlockingUpdate(using appStoreInfo: AppStoreLookupResponse.AppStoreInfo)
    func openAppStore(appStoreUrl: String)
}

final class AppUpdatePresenter: AppUpdatePresenterProtocol {
    func showNotice(using appStoreInfo: AppStoreLookupResponse.AppStoreInfo) {
        let viewModel = AppStoreInfoViewModel(appStoreInfo)
        let notice = Notice(
            title: viewModel.title,
            message: viewModel.message,
            feedbackType: .warning,
            style: InAppUpdateNoticeStyle(),
            actionTitle: viewModel.updateButtonTitle,
            cancelTitle: viewModel.cancelButtonTitle
        ) { accepted in
            if accepted {
                WPAnalytics.track(.inAppUpdateAccepted, properties: ["type": "flexible"])
                self.openAppStore(appStoreUrl: appStoreInfo.trackViewUrl)
            } else {
                WPAnalytics.track(.inAppUpdateDismissed)
            }
        }
        ActionDispatcher.dispatch(NoticeAction.post(notice))
        WPAnalytics.track(.inAppUpdateShown, properties: ["type": "flexible"])
    }

    func showBlockingUpdate(using appStoreInfo: AppStoreLookupResponse.AppStoreInfo) {
        guard let window = UIApplication.sharedIfAvailable()?.mainWindow,
              let topViewController = window.topmostPresentedViewController,
              !((topViewController as? UINavigationController)?.viewControllers.first is BlockingUpdateViewController) else {
            // Don't show if the view is already being displayed
            return
        }
        let viewModel = AppStoreInfoViewModel(appStoreInfo)
        let controller = BlockingUpdateViewController(viewModel: viewModel) {
            WPAnalytics.track(.inAppUpdateAccepted, properties: ["type": "blocking"])
            self.openAppStore(appStoreUrl: appStoreInfo.trackViewUrl)
        }
        let navigation = UINavigationController(rootViewController: controller)
        topViewController.present(navigation, animated: true)
    }

    func openAppStore(appStoreUrl: String) {
        guard let url = URL(string: appStoreUrl) else {
            return
        }
        UIApplication.shared.open(url)
    }
}
