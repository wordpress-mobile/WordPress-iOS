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
        self.view.backgroundColor = .white
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.barTintColor = .listBackground
        navigationBarAppearace.barStyle = .default
        navigationBarAppearace.tintColor = .primary
        navigationBarAppearace.titleTextAttributes = [.foregroundColor: UIColor.primary]
        navigationBarAppearace.isTranslucent = false
    }

    func loadAndPresentNavigationVC() {
        modularController.context = self.extensionContext
        modularController.dismissalCompletionBlock = {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }

        let shareNavController = MainDraftNavigationController(rootViewController: modularController)
        shareNavController.transitioningDelegate = extensionTransitioningManager
        shareNavController.modalPresentationStyle = .custom
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
