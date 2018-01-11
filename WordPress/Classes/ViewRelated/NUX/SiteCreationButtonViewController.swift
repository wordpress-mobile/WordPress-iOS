import UIKit

protocol SiteCreationButtonViewControllerDelegate {
    func continueButtonPressed()
}

class SiteCreationButtonViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet var shadowView: UIView?
    @IBOutlet var continueButton: UIButton?

    open var delegate: SiteCreationButtonViewControllerDelegate?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        continueButton?.titleLabel?.text = NSLocalizedString("Create site", comment: "Button text for creating a new site in the Site Creation process.")
    }

    // MARK: - Button Handling

    @IBAction func handleButtonPressed(_ sender: Any) {
        delegate?.continueButtonPressed()
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
