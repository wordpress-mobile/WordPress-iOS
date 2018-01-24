import UIKit

class SiteCreationEpilogueViewController: UIViewController {

    private var buttonViewController: NUXButtonViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
            buttonViewController?.delegate = self
            setButtonTitles()
        }
    }

    private func setButtonTitles() {
        let primaryTitle = NSLocalizedString("Write first post", comment: "")
        let secondaryTitle = NSLocalizedString("Configure", comment: "")
        buttonViewController?.setButtonTitles(primary: primaryTitle, secondary: secondaryTitle)
    }

}

// MARK: - NUXButtonViewControllerDelegate

extension SiteCreationEpilogueViewController: NUXButtonViewControllerDelegate {
    func primaryButtonPressed() {
    }

    func secondaryButtonPressed() {
    }
}
