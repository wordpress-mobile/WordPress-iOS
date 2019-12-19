import UIKit
import WordPressShared
import WordPressUI

fileprivate extension OriginatingExtension {
    var viewControllerIdentifier: String {
        switch self {
        case .saveToDraft:
            return "ShareModularViewController"
        case .share:
            return "ShareExtensionEditorViewController"
        }
    }
}

class MainShareViewController: UIViewController {

    fileprivate let extensionTransitioningManager: ExtensionTransitioningManager = {
        let manager = ExtensionTransitioningManager()
        manager.direction = .bottom
        return manager
    }()

    fileprivate let editorController: ShareExtensionAbstractViewController = {
        let storyboard = UIStoryboard(name: "ShareExtension", bundle: nil)


        let origination: OriginatingExtension

        if Bundle.main.bundleIdentifier == "org.wordpress.WordPressDraftAction" {
            origination = .saveToDraft
        } else {
            origination = .share
        }

        guard let controller = storyboard.instantiateViewController(withIdentifier: origination.viewControllerIdentifier) as? ShareExtensionAbstractViewController else {
            fatalError("Unable to create share extension editor screen.")
        }
        controller.originatingExtension = origination
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

        if #available(iOS 13, *), editorController.originatingExtension == .saveToDraft {
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
