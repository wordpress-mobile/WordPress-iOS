import UIKit

@objc protocol SiteCreationNavigationControllerDelegate {
    func showPostEditor()
    func showDetailsForSite(_ blog: Blog)
}

class SiteCreationNavigationController: RotationAwareNavigationViewController {

    var needToShowPostEditor: Bool = false
    var siteToShow: Blog?

    @objc var navControllerDelegate: SiteCreationNavigationControllerDelegate?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // If the user has chosen to 'write first post' from the epilogue,
        // inform the delegate to show the post editor.
        if needToShowPostEditor == true {
            navControllerDelegate?.showPostEditor()
            return
        }

        if let siteToShow = siteToShow {
            navControllerDelegate?.showDetailsForSite(siteToShow)
        }
    }

}
