import UIKit

@objc protocol SiteCreationNavigationControllerDelegate {
    func showPostEditor()
}

class SiteCreationNavigationController: RotationAwareNavigationViewController {

    var needToShowPostEditor: Bool = false
    @objc var navControllerDelegate: SiteCreationNavigationControllerDelegate?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // If the user has chosen to 'write first post' from the epilogue,
        // inform the delegate to show the post editor.
        if needToShowPostEditor == true {
            navControllerDelegate?.showPostEditor()
        }
    }

}
