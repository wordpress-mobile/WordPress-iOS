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
        let isSaveAsDraftAction = Bundle.main.bundleIdentifier?.contains("DraftAction") ?? false

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

        // Notice that this will set the apparence of _all_ `UINavigationBar` instances.
        //
        // Such a catch-all approach wouldn't be good in the context of a fully fledged application,
        // but is acceptable here, given we are in an app extension.
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.isTranslucent = false
        navigationBarAppearace.tintColor = .appBarTint
        navigationBarAppearace.barTintColor = .appBarBackground
        navigationBarAppearace.barStyle = .default

        // Extension-specif settings
        //
        // This view controller is shared via target membership by multiple extensions, resulting
        // in the need to apply some extension-specific settings.
        //
        // If we had the time, it would be great to extract all this logic in a standalone
        // framework or package, and then make the individual extensions import it, and instantiate
        // and configure the view controller to their liking, without making the code more complex
        // with branch-logic such as this.
        switch editorController.originatingExtension {
        case .saveToDraft:
            // This should probably be showing over current context but this just matches previous
            // behavior.
            view.backgroundColor = .basicBackground
        case .share:
            // Without this, the modal view controller will have a semi-transparent bar with a
            // very low alpha, making it close to fully transparent.
            navigationBarAppearace.backgroundColor = .basicBackground
        }
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

        // We need to make sure we don't end up with stacked modal view controllers by using this:
        shareNavController.modalPresentationStyle = .overCurrentContext

        present(shareNavController, animated: true)
    }

    func trackExtensionLaunch() {
        let tracks = Tracks(appGroupName: WPAppGroupName)
        let oauth2Token = ShareExtensionService.retrieveShareExtensionToken()
        tracks.trackExtensionLaunched(oauth2Token != nil)
    }
}
