import UIKit
import WordPressShared

class MainDraftActionViewController: UIViewController {

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
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.barTintColor = WPStyleGuide.lightGrey()
        navigationBarAppearace.barStyle = .default
        navigationBarAppearace.tintColor = WPStyleGuide.wordPressBlue()
        navigationBarAppearace.titleTextAttributes = [.foregroundColor: WPStyleGuide.wordPressBlue()]
        navigationBarAppearace.isTranslucent = false
    }

    func loadAndPresentNavigationVC() {
        editorController.context = self.extensionContext
        editorController.dismissalCompletionBlock = {
            // This extension doesn't mutate anything passed into it, so just echo the original items.
            self.extensionContext?.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
        }

        let shareNavController = UINavigationController(rootViewController: editorController)
        shareNavController.transitioningDelegate = extensionTransitioningManager
        shareNavController.modalPresentationStyle = .custom
        present(shareNavController, animated: true, completion: nil)
    }

    func trackExtensionLaunch() {
        let tracks = Tracks(appGroupName: WPAppGroupName)
        let oauth2Token = ShareExtensionService.retrieveShareExtensionToken()
        tracks.trackExtensionLaunched(oauth2Token != nil)
    }
}
