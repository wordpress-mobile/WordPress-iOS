import UIKit

class LoginEpilogueViewController: UIViewController {
    var originalPresentingVC: UIViewController?
    var dismissBlock: ((_ cancelled: Bool) -> Void)?

    // @IBAction to allow to set the selector for target in the storyboard
    @IBAction func unwindOut(segue: UIStoryboardSegue) {
        dismissBlock?(false)
    }
}
