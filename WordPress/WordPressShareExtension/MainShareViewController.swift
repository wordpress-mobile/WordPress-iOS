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

enum SharingErrors: Error {
    case canceled
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

        // Please forgive the following code - I believe there must be some other better way to architect our share
        // extension so that we don't need to check for the bundle ID.  But for the purpose of this bugfix it'll have
        // to do.
        //
        // This was proposed as a bug fix to the original expression:
        //      Bundle.main.bundleIdentifier == "org.wordpress.WordPressDraftAction"
        //
        // The problem with the original expression is that it didn't account for the bundle ID being different in
        // different build configurations (debug, internal, release).
        //
        let isSaveAsDraftAction = Bundle.main.bundleIdentifier?.hasSuffix("WordPressDraftAction") ?? false

        if isSaveAsDraftAction {
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

        if editorController.originatingExtension == .saveToDraft {
            // This should probably be showing over current context but this just matches previous behavior
            view.backgroundColor = .basicBackground
        }

        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.isTranslucent = false
        navigationBarAppearace.tintColor = .appBarTint
        navigationBarAppearace.barTintColor = .appBarBackground
        navigationBarAppearace.barStyle = .default
    }

    func loadAndPresentNavigationVC() {
        editorController.context = extensionContext
        editorController.dismissalCompletionBlock = { [weak self] (exitSharing) in
            if exitSharing {
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            } else {
                self?.extensionContext?.cancelRequest(withError: SharingErrors.canceled)
            }
        }

        let shareNavController = UINavigationController(rootViewController: editorController)

        if #available(iOS 13, *), editorController.originatingExtension == .saveToDraft {
            // iOS 13 has proper animations and presentations for share and action sheets. So the `else` case should be removed when iOS 13 is minimum.
            // We  need to make sure we don't end up with stacked modal view controllers by using this:
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
