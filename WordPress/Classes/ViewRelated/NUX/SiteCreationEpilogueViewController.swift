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

    private func handleButtonActions(showPostEditor: Bool, siteToShow: Blog? = nil) {
        if let navController = navigationController as? SiteCreationNavigationController {
            // SiteCreationNavigationController will check these values before dismissing
            // and take appropriate action.
            navController.needToShowPostEditor = showPostEditor
            navController.siteToShow = siteToShow
        }
        navigationController?.dismiss(animated: true, completion: nil)
    }

}

// MARK: - NUXButtonViewControllerDelegate

extension SiteCreationEpilogueViewController: NUXButtonViewControllerDelegate {

    // 'Write first post' button
    func primaryButtonPressed() {
        handleButtonActions(showPostEditor: true)
    }

    // 'Configure' button
    func secondaryButtonPressed() {
        handleButtonActions(showPostEditor: false, siteToShow: siteToShow)
    }
}
