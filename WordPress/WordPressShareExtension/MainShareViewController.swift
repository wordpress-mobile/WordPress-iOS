import Foundation
import UIKit

class MainShareViewController: UIViewController {

    private lazy var extensionTransitioningManager = ExtensionTransitioningManager()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        loadAndPresentNavigationVC()
    }

    func loadAndPresentNavigationVC() {
        let storyboard = UIStoryboard(name: "ShareExtension", bundle: nil)
        if let nav = storyboard.instantiateViewController(withIdentifier: "ShareNavigationController") as? UINavigationController {
            extensionTransitioningManager.direction = .bottom
            nav.transitioningDelegate = extensionTransitioningManager
            nav.modalPresentationStyle = .custom
            if let editor = nav.topViewController as? ShareExtensionEditorViewController {
                editor.context = self.extensionContext
                editor.cancelCompletionBlock = {
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                }
            }

            present(nav, animated: true, completion: nil)
        }
    }
}
