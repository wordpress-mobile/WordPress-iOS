import AuthenticationServices
import Foundation

class WebAuthenticationPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    let viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return viewController.view.window!
    }
}
