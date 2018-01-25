import UIKit

@objc protocol SiteCreationNavigationControllerDelegate {
    func showPostEditor()
}

class SiteCreationNavigationController: RotationAwareNavigationViewController {

    var needToShowPostEditor: Bool = false
    @objc var navControllerDelegate: SiteCreationNavigationControllerDelegate?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if needToShowPostEditor == true {
            navControllerDelegate?.showPostEditor()
        }
    }

}
