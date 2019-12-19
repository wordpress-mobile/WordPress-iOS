import UIKit
import WordPressShared
import WordPressUI

class MainShareViewController: UIViewController {

    fileprivate let extensionTransitioningManager: ExtensionTransitioningManager = {
        let manager = ExtensionTransitioningManager()
        manager.direction = .bottom
        return manager
    }()

    fileprivate let editorController: ShareExtensionEditorViewController = {
        let storyboard = UIStoryboard(name: "ShareExtension", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "ShareExtensionEditorViewController") as? ShareExtensionEditorViewController else {
            fatalError("Unable to create share extension editor screen.")
        }
        controller.originatingExtension = .share
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

private extension MainShareViewController {
    func setupAppearance() {
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.isTranslucent = false
        navigationBarAppearace.tintColor = .white
        navigationBarAppearace.barTintColor = .appBar
        navigationBarAppearace.barStyle = .default
    }

    func loadAndPresentNavigationVC() {
        editorController.context = self.extensionContext
        editorController.dismissalCompletionBlock = {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }

        let shareNavController = UINavigationController(rootViewController: editorController)

        if #available(iOS 13, *) {
            // iOS 13 has proper animations and presentations for share and action sheets.
            // We just need to make sure we don't end up with stacked modal view controllers by using this:
            shareNavController.modalPresentationStyle = .overFullScreen
        } else {
            shareNavController.transitioningDelegate = extensionTransitioningManager
            shareNavController.modalPresentationStyle = .custom
        }

        present(shareNavController, animated: true)
    }

    func trackExtensionLaunch() {
        let tracks = Tracks(appGroupName: WPAppGroupName)
        let oauth2Token = ShareExtensionService.retrieveShareExtensionToken()
        tracks.trackExtensionLaunched(oauth2Token != nil)
    }
}
