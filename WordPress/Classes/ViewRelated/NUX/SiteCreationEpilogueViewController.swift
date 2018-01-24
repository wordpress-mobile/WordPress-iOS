import UIKit

class SiteCreationEpilogueViewController: UIViewController {

    // MARK: - Properties

    var siteToShow: Blog?

    private var previewViewController: SiteCreationSitePreviewViewController?
    private var buttonViewController: NUXButtonViewController?

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - View

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? SiteCreationSitePreviewViewController {
            vc.siteUrl = siteToShow?.url
            previewViewController = vc
        }

        if let vc = segue.destination as? NUXButtonViewController {
            vc.delegate = self
            buttonViewController = vc
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
