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
        let primaryTitle = NSLocalizedString("Write first post", comment: "On the final site creation page, button to allow the user to write a post for the newly created site.")
        let secondaryTitle = NSLocalizedString("Configure", comment: "Button to allow the user to dismiss the final site creation page.")
        buttonViewController?.setButtonTitles(primary: primaryTitle, secondary: secondaryTitle)
    }

}

// MARK: - NUXButtonViewControllerDelegate

extension SiteCreationEpilogueViewController: NUXButtonViewControllerDelegate {

    // 'Write first post' button
    func primaryButtonPressed() {
        if let navController = navigationController as? SiteCreationNavigationController {
            // SiteCreationNavigationController will check this value before dismissing
            // and take appropriate action.
            navController.needToShowPostEditor = true
        }
        navigationController?.dismiss(animated: true, completion: nil)
    }

    // 'Configure' button
    func secondaryButtonPressed() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
