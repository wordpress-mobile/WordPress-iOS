import UIKit

class SiteCreationNavigationController: RotationAwareNavigationViewController {

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SiteCreationFields.resetSharedInstance()
    }

}
