import UIKit

class SiteCreationEpilogueViewController: UIViewController {

    // MARK: - Properties

    private var previewViewController: SiteCreationSitePreviewViewController?
    private var buttonViewController: NUXButtonViewController?

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - View

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

        if let vc = segue.destination as? SiteCreationSitePreviewViewController {
            previewViewController = vc
        }

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
            buttonViewController?.delegate = self
            setButtonTitles()
        }
    }

    // MARK: - Button View Button Titles

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
