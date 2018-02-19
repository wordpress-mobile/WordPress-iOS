import UIKit

class SignupEpilogueViewController: NUXViewController {

    // MARK: - Properties

    private var buttonViewController: NUXButtonViewController?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
            buttonViewController?.delegate = self
            buttonViewController?.setButtonTitles(primary: NSLocalizedString("Continue", comment: "Button text on site creation epilogue page to proceed to My Sites."))
        }
    }

}

// MARK: - NUXButtonViewControllerDelegate

extension SignupEpilogueViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
    }
}
