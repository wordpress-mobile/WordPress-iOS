import UIKit
import WordPressShared

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
        self.view.backgroundColor = UIColor.white
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.barTintColor = WPStyleGuide.lightGrey()
        navigationBarAppearace.barStyle = .default
        navigationBarAppearace.tintColor = WPStyleGuide.wordPressBlue()
        navigationBarAppearace.titleTextAttributes = [.foregroundColor: WPStyleGuide.wordPressBlue()]
        navigationBarAppearace.isTranslucent = false
    }

    func loadAndPresentNavigationVC() {
        modularController.context = self.extensionContext
        modularController.dismissalCompletionBlock = {
            // This extension doesn't mutate anything passed into it, so just echo the original items.
            self.extensionContext?.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
        }

        let shareNavController = UINavigationController(rootViewController: modularController)
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
