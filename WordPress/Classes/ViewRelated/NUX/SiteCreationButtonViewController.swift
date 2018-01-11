import UIKit

class SiteCreationButtonViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet var shadowView: UIView?
    @IBOutlet var continueButton: UIButton?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        continueButton?.titleLabel?.text = NSLocalizedString("Create site", comment: "Button text for creating a new site in the Site Creation process.")
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
