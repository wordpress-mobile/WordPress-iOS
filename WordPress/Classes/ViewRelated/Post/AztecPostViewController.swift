import Foundation
import UIKit

class AztecPostViewController: UIViewController
{
    override func viewDidLoad() {
        title = NSLocalizedString("Aztec Native Editor", comment: "")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done,
                                                                target: self,
                                                                action: #selector(AztecPostViewController.closeAction))
        view.backgroundColor = UIColor.whiteColor()
    }

    func closeAction(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
