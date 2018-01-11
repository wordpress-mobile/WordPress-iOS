import UIKit
import WordPressShared

class MainShareViewController: UIViewController {

    fileprivate let extensionTransitioningManager: ExtensionTransitioningManager = {
        $0.direction = .bottom
        return $0
    }(ExtensionTransitioningManager())

    fileprivate let shareNavController: UINavigationController = {
        let storyboard = UIStoryboard(name: "ShareExtension", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "ShareNavigationController") as! UINavigationController
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        loadAndPresentNavigationVC()
    }
}

// MARK: - Private Helpers

private extension MainShareViewController {
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
            editor.cancelCompletionBlock = {
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        }

        present(shareNavController, animated: true, completion: nil)
    }
}
