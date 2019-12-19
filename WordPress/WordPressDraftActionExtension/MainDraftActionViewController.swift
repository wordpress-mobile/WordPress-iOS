import UIKit
import WordPressShared
import WordPressUI

class MainDraftActionViewController: UIViewController {

    fileprivate let extensionTransitioningManager: ExtensionTransitioningManager = {
        let manager = ExtensionTransitioningManager()
        manager.direction = .bottom
        return manager
    }()

    fileprivate let modularController: ShareModularViewController = {
        let storyboard = UIStoryboard(name: "ShareExtension", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "ShareModularViewController") as? ShareModularViewController else {
            fatalError("Unable to create share extension modular screen.")
        }
        controller.originatingExtension = .saveToDraft
        return controller
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .overFullScreen
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        trackExtensionLaunch()
        setupAppearance()
        loadAndPresentNavigationVC()
    }
}

// MARK: - Private Helpers

private extension MainDraftActionViewController {
    func setupAppearance() {
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.isTranslucent = false
        navigationBarAppearace.tintColor = .white
        navigationBarAppearace.barTintColor = .appBar
        navigationBarAppearace.barStyle = .default
    }

    func loadAndPresentNavigationVC() {
        modularController.context = self.extensionContext
        modularController.dismissalCompletionBlock = {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }

        let shareNavController = MainDraftNavigationController(rootViewController: modularController)
        if #available(iOS 13, *) {
            // iOS 13 has proper animations and presentations for share and action sheets.
            // We just need to make sure we don't end up with stacked modal view controllers by using this:
            shareNavController.modalPresentationStyle = .overFullScreen
        } else {
            shareNavController.transitioningDelegate = extensionTransitioningManager
            shareNavController.modalPresentationStyle = .custom
        }
        present(shareNavController, animated: !shareNavController.shouldFillContentContainer)
    }

    func trackExtensionLaunch() {
        let tracks = Tracks(appGroupName: WPAppGroupName)
        let oauth2Token = ShareExtensionService.retrieveShareExtensionToken()
        tracks.trackExtensionLaunched(oauth2Token != nil)
    }
}

private class MainDraftNavigationController: UINavigationController, ExtensionPresentationTarget {
    var shouldFillContentContainer: Bool {
        // On iPad, we want the draft action extension to be displayed full size within the
        // presenting view controller, to avoid graphical issues.
        // See https://github.com/wordpress-mobile/WordPress-iOS/issues/8646 for more info.
        return UIDevice.isPad()
    }
}
