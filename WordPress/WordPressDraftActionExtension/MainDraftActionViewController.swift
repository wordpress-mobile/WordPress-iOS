import UIKit
import WordPressShared

class MainDraftActionViewController: UIViewController {

    fileprivate let extensionTransitioningManager: ExtensionTransitioningManager = {
        let manager = ExtensionTransitioningManager()
        manager.direction = .bottom
        return manager
    }()

    fileprivate let shareNavController: UINavigationController = {
        let storyboard = UIStoryboard(name: "ShareExtension", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "ShareNavigationController") as! UINavigationController
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
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.barTintColor = WPStyleGuide.lightGrey()
        navigationBarAppearace.barStyle = .default
        navigationBarAppearace.tintColor = WPStyleGuide.wordPressBlue()
        navigationBarAppearace.titleTextAttributes = [.foregroundColor: WPStyleGuide.wordPressBlue()]
        navigationBarAppearace.isTranslucent = false
    }

    func loadAndPresentNavigationVC() {
        shareNavController.transitioningDelegate = extensionTransitioningManager
        shareNavController.modalPresentationStyle = .custom
        if let editor = shareNavController.topViewController as? ShareExtensionEditorViewController {
            editor.context = self.extensionContext
            editor.dismissalCompletionBlock = {
                // This extension doesn't mutate anything passed into it, so just echo the original items.
                self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
            }
        }
        present(shareNavController, animated: true, completion: nil)
    }

    func trackExtensionLaunch() {
        let tracks = Tracks(appGroupName: WPAppGroupName)
        let oauth2Token = ShareExtensionService.retrieveShareExtensionToken()
        tracks.trackExtensionLaunched(oauth2Token != nil)
    }
}
